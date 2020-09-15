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
  printf "Please include a domain name with -d"
  exit 1
fi

# check for host argument
if [[ $HOSTS == '' ]]
then
  printf "Please include at least one host IP address with -h"
  exit 1
fi

BASE_DIR=/etc/letsencrypt/archive/$DOMAIN

printf "Requesting Lets Encrypt certificate for $DOMAIN...\n"
sudo certbot certonly --webroot -w /usr/share/nginx/html -d $DOMAIN --cert-name $DOMAIN

printf "\nDeploying certificate...\n"
for host in "${HOSTS[@]}"; do
  rsync -a $BASE_DIR certbot@$host:/etc/ssl/le/
done

printf "\nFinished.\n"
