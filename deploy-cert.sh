#!/bin/bash

while getopts ":d:h:" opt; do
  case $opt in
    d) DOMAIN="$OPTARG"
    ;;
    h) HOSTS+=("$OPTARG")
    ;;
    \?) printf "Invalid option -$OPTARG" && exit 1
    ;;
  esac
done

# check for domain argument
if [[ $DOMAIN == '' ]]
then
  printf "Please include a domain name with -d\n"
  exit 1
fi

# check for host argument
if [[ $HOSTS == '' ]]
then
  printf "Please include at least one host IP address with -h\n"
  exit 1
fi

BASE_DIR=/etc/letsencrypt/live/$DOMAIN

read -p "Use HTTP or DNS for the domain challenge [http|dns]? " CHALLENGE

## Format CHALLENGE in all lowercase
CHALLENGE=$(printf $CHALLENGE | tr "{A-Z}" "{a-z}")

if [[ $CHALLENGE == http ]]
then
  printf "Requesting Lets Encrypt certificate for $DOMAIN with HTTP challenge...\n"
  sudo certbot certonly --webroot -w /usr/share/nginx/html -d $DOMAIN
elif [[ $CHALLENGE == dns ]]
then
  printf "Validate DNS acme-server\n"
  read -p "Please enter the FQDN for the acme-dns server, then press enter: " SERVER

  ## Format SERVER in all lowercase
  SERVER=$(printf $SERVER | tr "{A-Z}" "{a-z}")

  printf "\n"
  read -n1 -rsp "Is this correct? $SERVER [Y|N] " CONFIRMSVR

  ## Format response in all uppercase
  CONFIRMSVR=$(printf $CONFIRMSVR | tr "{y}" "{Y}")

  if [[ $CONFIRMSVR == Y ]]
  then
    printf "\nChecking health of acme-dns server...\n"
    curl -sSI --stderr le-cms_acmestatus -X GET https://$SERVER/health > le-cms_acmestatus

    awk 'BEGIN {
        RS="\n"
    }
    /^HTTP/{
      if ((NR == 1) && ($2 == 200)) {
        printf("%s %s\n", "acme-dns - OK: status", $2)
      } else if (NR != 1) {
        # ignore other HTTP sections
      } else {
        printf("%s %s\n", "acme-dns - FAILED: status", $2 ", expecting 200")
        printf ("%s\n", "Exiting...")
        exit 1
      }
    } ' le-cms_acmestatus

    # check for typical errors
    awk 'BEGIN {
        RS="\n"
    }
    /^curl/{
      if ((NR == 1) && ($2 == "(6)")) {
        printf("%s\n", "acme-dns - FAILED: Could not resolve host")
        printf("%s\n", "Exiting...")
        exit 1
      }
    } ' le-cms_acmestatus

    rm -f le-cms_acmestatus

    printf "Requesting Lets Encrypt certificate for $DOMAIN with DNS challenge...\n"
    sudo certbot certonly --manual --manual-auth-hook /etc/letsencrypt/acme-dns-auth.py --preferred-challenges dns --debug-challenges -d $DOMAIN
  else
    printf "Exiting..."
    exit 0
  fi
else
  printf "Invalid challenge option - $CHALLENGE"
  exit 1
fi

printf "\nDeploying certificate...\n"
for host in "${HOSTS[@]}"; do
  rsync -a $BASE_DIR certbot@$host:/etc/ssl/le/
done

printf "\nFinished.\n"
exit 0
