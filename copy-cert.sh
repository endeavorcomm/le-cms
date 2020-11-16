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
  echo "Please include at least one host IP address with -h"
  exit 1
fi

printf "\nDeploying certificates for $DOMAIN...\n"
for host in "${HOSTS[@]}"; do
  rsync -e 'ssh -i /home/certbot/.ssh/id_rsa' -L /etc/letsencrypt/live/$DOMAIN/cert.pem certbot@$host:/etc/ssl/le/$DOMAIN/cert.pem
  rsync -e 'ssh -i /home/certbot/.ssh/id_rsa' -L /etc/letsencrypt/live/$DOMAIN/chain.pem certbot@$host:/etc/ssl/le/$DOMAIN/chain.pem
  rsync -e 'ssh -i /home/certbot/.ssh/id_rsa' -L /etc/letsencrypt/live/$DOMAIN/fullchain.pem certbot@$host:/etc/ssl/le/$DOMAIN/fullchain.pem
  rsync -e 'ssh -i /home/certbot/.ssh/id_rsa' -L /etc/letsencrypt/live/$DOMAIN/privkey.pem certbot@$host:/etc/ssl/le/$DOMAIN/privkey.pem
done