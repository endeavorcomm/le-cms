#!/bin/bash

CONFIGPATH="/etc/apache2/sites-available/"
CERTPATH="/etc/ssl/le/"

printf "\nReady to deploy sites.\n\n"
read -p "Please enter the domain name for your site certificate, then press enter: " DOMAIN

## Format DOMAIN in all lowercase
DOMAIN=$(printf $DOMAIN | tr "{A-Z}" "{a-z}")

printf "\n"
read -n1 -rsp "Is this correct? $DOMAIN [Y|N] " CONFIRMDOM

## Format response in all uppercase
CONFIRMDOM=$(printf $CONFIRMDOM | tr "{y}" "{Y}")

DEFAULT=".conf"
SECURE="-le-ssl.conf"

if [[ $CONFIRMDOM == Y ]]
then
  printf "\nChecking for existing $DOMAIN sites...\n"
  if [[ -f $CONFIGPATH$DOMAIN$DEFAULT && -f $CONFIGPATH$DOMAIN$SECURE ]]
  then
    printf "$CONFIGPATH$DOMAIN$DEFAULT and $CONFIGPATH$DOMAIN$SECURE already exist. \nExiting...\n"
    exit 1
  elif [ -f $CONFIGPATH$DOMAIN$DEFAULT ]
  then
    printf "$CONFIGPATH$DOMAIN$DEFAULT already exists. \nExiting...\n"
    exit 1
  elif [ -f $CONFIGPATH$DOMAIN$SECURE ]
  then
    printf "$CONFIGPATH$DOMAIN$SECURE already exists. \nExiting...\n"
    exit 1
  else
    printf "Checks Passed.\n"
  fi

  read -p "Please enter the domain name for your certificate management server, then press enter: " SERVER

  ## Format SERVER in all lowercase
  SERVER=$(printf $SERVER | tr "{A-Z}" "{a-z}")

  printf "\n"
  read -n1 -rsp "Is this correct? $SERVER [Y|N] " CONFIRMSVR

  ## Format response in all uppercase
  CONFIRMSVR=$(printf $CONFIRMSVR | tr "{y}" "{Y}")

  if [[ $CONFIRMSVR == Y ]]
  then
    printf "\nCreating HTTP site...\n"
    sudo printf "<VirtualHost *:80>\n\tServerName $DOMAIN\n\tRedirect 301 /.well-known/acme-challenge http://$SERVER/.well-known/acme-challenge\n\tDocumentRoot /var/www/html\n\tRewriteEngine on\n\tRewriteCond %%{REQUEST_URI} !^/.well-known/acme-challenge\n\tRewriteRule ^ https://%%{SERVER_NAME}%%{REQUEST_URI} [END,NE,R=permanent]\n</VirtualHost>\n" > $CONFIGPATH$DOMAIN$DEFAULT

    ## Verify http site was created
    if [ -f $CONFIGPATH$DOMAIN$DEFAULT ]
    then
      printf "Enabling HTTP site...\n"
      sudo a2ensite -q $DOMAIN$DEFAULT

      printf "Reloading the Apache service...\n"
      sudo systemctl reload apache2

      printf "HTTP site ready.\n"
      printf "\nSTOP! If you are using multiple servers to host $DOMAIN, connect to them now and run this same script.\n"
      printf "After all HTTP sites have been created, deploy TLS certificates from your management server before continuing.\n\n"
      read -n1 -rsp "Once TLS certificates are ready, press Y... " KEY

      ## Format response in all uppercase
      KEY=$(printf $KEY | tr "{y}" "{Y}")

      if [ $KEY == Y  ]
      then
        printf "\n\nVerifying certificate files...\n"
        if [[ -f $CERTPATH$DOMAIN/cert1.pem && -f $CERTPATH$DOMAIN/fullchain1.pem && -f $CERTPATH$DOMAIN/chain1.pem ]]
        then
          printf "Certificate files found.\n"
          ## Begin creating https site further below
        else
          printf "One or more certificate files not found. Removing HTTP site and exiting...\n"
          sudo a2dissite -q $DOMAIN$DEFAULT
          sudo rm -f $CONFIGPATH$DOMAIN$DEFAULT
          exit 1
        fi
      else
        printf "\n\nYou did not press Y. Removing HTTP site and exiting...\n"
        sudo a2dissite -q $DOMAIN$DEFAULT
        sudo rm -f $CONFIGPATH$DOMAIN$DEFAULT
        exit 1
      fi
    else
      printf "We were not able to create the HTTP site. Exiting...\n"
      exit 1
    fi

    ## Create HTTPS site
    printf "\nCreating HTTPS site...\n"
    sudo printf "<IfModule mod_ssl.c>\n<VirtualHost *:443>\n\tServerName $DOMAIN\n\tDocumentRoot /var/www/html\n\tSSLCertificateFile /etc/ssl/le/$DOMAIN/fullchain1.pem\n\tSSLCertificateKeyFile /etc/ssl/le/$DOMAIN/privkey1.pem\n\tInclude /etc/apache2/options-ssl.conf\n</VirtualHost>\n</IfModule>\n" > $CONFIGPATH$DOMAIN$SECURE

    ## Verify https site was created
    if [ -f $CONFIGPATH$DOMAIN$SECURE ]
    then
      ## Enable sites
      printf "Enabling HTTPS site...\n"
      sudo a2ensite -q $DOMAIN$SECURE

      ## Restart Apache
      printf "Reloading the Apache service...\n"
      sudo systemctl reload apache2
      printf "HTTPS site ready.\n"
    else
      printf "We were not able to create the HTTPS site. Removing HTTP site and exiting...\n"
      sudo a2dissite -q $DOMAIN$DEFAULT
      sudo rm -f $CONFIGPATH$DOMAIN$DEFAULT
      exit 1
    fi

    printf "\nVerifiying HTTP and HTTPS connectivity...\n"
    # check if http permanently redirects to https
    curl -sSLI --stderr httpstatus http://$DOMAIN > le-cms_httpstatus
    
    awk 'BEGIN {
        RS="\n"
    }
    /^HTTP/{
      if ((NR == 1) && ($2 == 301)) {
        printf("%s %s\n", "HTTP redirecting to HTTPS - OK: status", $2)
      } else if (NR != 1) {
        # ignore other HTTP sections
      } else {
        printf("%s %s\n", "HTTP redirecting to HTTPS - FAILED: status", $2 ", expecting 301")
      }
    } ' le-cms_httpstatus

    # check for typical errors
    awk 'BEGIN {
        RS="\n"
    }
    /^curl/{
      if ((NR == 1) && ($2 == "(6)")) {
        printf("%s\n", "HTTP redirecting to HTTPS - FAILED: Could not resolve host")
      } else if ((NR == 1) && ($2 == "(60)")) {
        printf("%s\n", "HTTP redirecting to HTTPS - OK")
      }
    } ' le-cms_httpstatus

    rm -f le-cms_httpstatus


    # check if https is responding
    curl -sSI --stderr httpstatus https://$DOMAIN > le-cms_httpstatus

    awk 'BEGIN {
        RS="\n"
    }
    /^HTTP/{
      if ((NR == 1) && ($2 == 200)) {
        printf("%s %s\n", "HTTPS Responding - OK: status", $2)
      } else if (NR != 1) {
        # ignore other HTTP sections
      } else {
        printf("%s %s\n", "HTTPS Responding - FAILED", $2)
      }
    } ' le-cms_httpstatus

    # check for typical errors
    awk 'BEGIN {
        RS="\n"
    }
    /^curl/{
      if ((NR == 1) && ($2 == "(35)")) {
        printf("%s\n", "HTTPS Responding - FAILED")
      } else if ((NR == 1) && ($2 == "(6)")) {
        printf("%s\n", "HTTPS responding - FAILED: Could not resolve host")
      } else if ((NR == 1) && ($2 == "(60)")) {
        printf("%s\n", "HTTPS responding, but certificate is invalid for your domain name - FAILED")
      }
    } ' le-cms_httpstatus

    rm -f le-cms_httpstatus
    printf "\nFinished.\n"
    exit 0
  else
    printf "\nCancelling...\n"
    exit 1
  fi
else
  printf "\nCancelling...\n"
  exit 1
fi
