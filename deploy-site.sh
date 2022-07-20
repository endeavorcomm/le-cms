#!/usr/bin/env bash

CERTPATH="/etc/ssl/le/"

read -p "Which web server are you using [apache2|nginx]? " WEBSERVER

## Format WEBSERVER in all lowercase
WEBSERVER=$(printf $WEBSERVER | tr "{A-Z}" "{a-z}")

printf "\n"
read -n1 -rsp "Is this correct? $WEBSERVER [Y|N] " CONFIRMWEBSERVER

## Format response in all uppercase
CONFIRMWEBSERVER=$(printf $CONFIRMWEBSERVER | tr "{y}" "{Y}")

if [[ $CONFIRMWEBSERVER == Y ]]
then
  printf "\n"
  if [[ $WEBSERVER == apache2 ]]
  then
    DEFAULT=".conf"
    SECURE="-le-ssl.conf"
  elif [[ $WEBSERVER == nginx ]]
  then
    DEFAULT=""
    SECURE="-le-ssl"
  else
    printf "Invalid webserver option - $WEBSERVER"
    exit 1
  fi
  CONFIGPATH="/etc/$WEBSERVER/sites-available/"
else
  printf "\nCancelling...\n"
  exit 1
fi

read -p "Please enter the domain name for your site: " DOMAIN

## Format DOMAIN in all lowercase
DOMAIN=$(printf $DOMAIN | tr "{A-Z}" "{a-z}")

printf "\n"
read -n1 -rsp "Is this correct? $DOMAIN [Y|N] " CONFIRMDOM

## Format response in all uppercase
CONFIRMDOM=$(printf $CONFIRMDOM | tr "{y}" "{Y}")

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

  read -p "Please enter the domain name for your certificate management server: " SERVER

  ## Format SERVER in all lowercase
  SERVER=$(printf $SERVER | tr "{A-Z}" "{a-z}")

  printf "\n"
  read -n1 -rsp "Is this correct? $SERVER [Y|N] " CONFIRMSVR

  ## Format response in all uppercase
  CONFIRMSVR=$(printf $CONFIRMSVR | tr "{y}" "{Y}")

  if [[ $CONFIRMSVR == Y ]]
  then
    printf "\nCreating HTTP site...\n"
    if [[ $WEBSERVER == apache2 ]]
    then
      sudo printf "<VirtualHost *:80>\n\tServerName $DOMAIN\n\tRedirect 301 /.well-known/acme-challenge http://$SERVER/.well-known/acme-challenge\n\tDocumentRoot /var/www/html\n\tRewriteEngine on\n\tRewriteCond %%{REQUEST_URI} !^/.well-known/acme-challenge\n\tRewriteRule ^ https://%%{SERVER_NAME}%%{REQUEST_URI} [END,NE,R=permanent]\n</VirtualHost>\n" > $CONFIGPATH$DOMAIN$DEFAULT
    elif [[ $WEBSERVER == nginx ]]
    then
      sudo printf "server {\n\tlisten 80;\n\tlisten [::]:80;\n\tserver_name $DOMAIN;\n\troot /usr/share/nginx/html;\n\trewrite ^/.well-known/acme-challenge http://$SERVER\$request_uri permanent;\n\treturn 301 https://\$host\$request_uri;\n}\n" > $CONFIGPATH$DOMAIN$DEFAULT
    fi

    ## Verify http site was created
    if [ -f $CONFIGPATH$DOMAIN$DEFAULT ]
    then
      printf "Enabling HTTP site...\n"
      if [[ $WEBSERVER == apache2 ]]
      then
        sudo a2ensite -q $DOMAIN$DEFAULT
      elif [[ $WEBSERVER == nginx ]]
      then
        sudo ln -s /etc/nginx/sites-available/$DOMAIN$DEFAULT /etc/nginx/sites-enabled/$DOMAIN$DEFAULT
      fi

      printf "Reloading the $WEBSERVER service...\n"
      if [[ $WEBSERVER == apache2 ]]
      then
        sudo apachectl -k graceful
      elif [[ $WEBSERVER == nginx ]]
      then
        sudo nginx -s reload
      fi

      printf "HTTP site ready.\n"
      printf "\nSTOP! If you are using multiple servers to host $DOMAIN, connect to them now and run this same script.\n"
      printf "After all HTTP sites have been created, deploy TLS certificates from your management server before continuing.\n\n"
      read -n1 -rsp "Once TLS certificates are ready, press Y... " KEY

      ## Format response in all uppercase
      KEY=$(printf $KEY | tr "{y}" "{Y}")

      if [ $KEY == Y  ]
      then
        printf "\n\nVerifying certificate files...\n"
        if [[ -f $CERTPATH$DOMAIN/cert.pem && -f $CERTPATH$DOMAIN/fullchain.pem && -f $CERTPATH$DOMAIN/chain.pem ]]
        then
          printf "Certificate files found.\n"
          ## Begin creating https site further below
        else
          printf "One or more certificate files not found. Removing HTTP site and exiting...\n"
          if [[ $WEBSERVER == apache2 ]]
          then
            sudo a2dissite -q $DOMAIN$DEFAULT
          elif [[ $WEBSERVER == nginx ]]
          then
            sudo rm -f /etc/nginx/sites-enabled/$DOMAIN$DEFAULT
          fi
          sudo rm -f $CONFIGPATH$DOMAIN$DEFAULT
          exit 1
        fi
      else
        printf "\n\nYou did not press Y. Removing HTTP site and exiting...\n"
        if [[ $WEBSERVER == apache2 ]]
        then
          sudo a2dissite -q $DOMAIN$DEFAULT
        elif [[ $WEBSERVER == nginx ]]
        then
          sudo rm -f /etc/nginx/sites-enabled/$DOMAIN$DEFAULT
        fi
        sudo rm -f $CONFIGPATH$DOMAIN$DEFAULT
        exit 1
      fi
    else
      printf "We were not able to create the HTTP site. Exiting...\n"
      exit 1
    fi

    ## Create HTTPS site
    printf "\nCreating HTTPS site...\n"
    if [[ $WEBSERVER == apache2 ]]
    then
      sudo printf "<IfModule mod_ssl.c>\n<VirtualHost *:443>\n\tServerName $DOMAIN\n\tDocumentRoot /var/www/html\n\tSSLCertificateFile /etc/ssl/le/$DOMAIN/fullchain.pem\n\tSSLCertificateKeyFile /etc/ssl/le/$DOMAIN/privkey.pem\n\tInclude /etc/apache2/options-ssl.conf\n</VirtualHost>\n</IfModule>\n" > $CONFIGPATH$DOMAIN$SECURE
    elif [[ $WEBSERVER == nginx ]]
    then
      sudo printf "server {\n\tlisten 443 ssl;\n\tlisten [::]:443 ssl;\n\tserver_name $DOMAIN;\n\troot /usr/share/nginx/html;\n\tssl_certificate /etc/ssl/le/$DOMAIN/fullchain.pem;\n\tssl_certificate_key /etc/ssl/le/$DOMAIN/privkey.pem;\n\tssl_session_timeout 1d;\n\tssl_session_cache shared:MozSSL:10m;\n\tssl_session_tickets off;\n\tssl_protocols TLSv1.2 TLSv1.3;\n\tssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;\n\tssl_prefer_server_ciphers off;\n\tssl_stapling on;\n}\n" > $CONFIGPATH$DOMAIN$SECURE
    fi

    ## Verify https site was created
    if [ -f $CONFIGPATH$DOMAIN$SECURE ]
    then
      ## Enable sites
      printf "Enabling HTTPS site...\n"
      if [[ $WEBSERVER == apache2 ]]
      then
        sudo a2ensite -q $DOMAIN$SECURE
      elif [[ $WEBSERVER == nginx ]]
      then
        sudo ln -s /etc/nginx/sites-available/$DOMAIN$SECURE /etc/nginx/sites-enabled/$DOMAIN$SECURE
      fi

      printf "Reloading the $WEBSERVER service...\n"
      if [[ $WEBSERVER == apache2 ]]
      then
        sudo apachectl -k graceful
      elif [[ $WEBSERVER == nginx ]]
      then
        sudo nginx -s reload
      fi
      printf "HTTPS site ready.\n"
    else
      printf "We were not able to create the HTTPS site. Removing HTTP site and exiting...\n"
      if [[ $WEBSERVER == apache2 ]]
      then
        sudo a2dissite -q $DOMAIN$SECURE
      elif [[ $WEBSERVER == nginx ]]
      then
        sudo rm -f /etc/nginx/sites-enabled/$DOMAIN$SECURE
      fi
      sudo rm -f $CONFIGPATH$DOMAIN$SECURE
      exit 1
    fi
  else
    printf "\nCancelling...\n"
    exit 1
  fi
else
  printf "\nCancelling...\n"
  exit 1
fi
