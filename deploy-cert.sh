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

BASE_DIR=/etc/letsencrypt/archive/$DOMAIN

read -p "Use HTTP or DNS for the domain challenge [http|dns]? " CHALLENGE

## Format CHALLENGE in all lowercase
CHALLENGE=$(printf $CHALLENGE | tr "{A-Z}" "{a-z}")

if [[ $CHALLENGE == http ]]
then
  printf "Requesting Lets Encrypt certificate for $DOMAIN with HTTP challenge...\n"
  sudo certbot certonly --webroot -w /usr/share/nginx/html -d $DOMAIN
elif [[ $CHALLENGE == dns ]]
then
  printf "Requesting Lets Encrypt certificate for $DOMAIN with DNS challenge...\n"
  sudo certbot certonly --manual --manual-auth-hook /etc/letsencrypt/acme-dns-auth.py --preferred-challenges dns --debug-challenges -d $DOMAIN
else
  printf "Invalid challenge option - $CHALLENGE\n"
  exit 1
fi

printf "\nDeploying certificate...\n"
for host in "${HOSTS[@]}"; do
  rsync -a $BASE_DIR certbot@$host:/etc/ssl/le/
done

printf "\nFinished.\n"
exit 0