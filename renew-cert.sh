#!/usr/bin/env bash
HOSTS=''

while getopts "h:s" opt; do
  case $opt in
    h) HOSTS="$OPTARG"
    ;;
    /?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac
done

# check for host argument
if [[ $HOSTS == '' ]]
then
  echo "Please include at least one host IP address with -h"
  exit 1
fi

IFS=", " read -ra hosts <<< $HOSTS

# assign domain name for renewed cert
DOMAIN=$(basename $RENEWED_LINEAGE)

for host in "${hosts[@]}"; do
  rsync -e 'ssh -i /home/certbot/.ssh/id_rsa' -L $RENEWED_LINEAGE/cert.pem certbot@$host:/etc/ssl/le/$DOMAIN/cert.pem
  rsync -e 'ssh -i /home/certbot/.ssh/id_rsa' -L $RENEWED_LINEAGE/chain.pem certbot@$host:/etc/ssl/le/$DOMAIN/chain.pem
  rsync -e 'ssh -i /home/certbot/.ssh/id_rsa' -L $RENEWED_LINEAGE/fullchain.pem certbot@$host:/etc/ssl/le/$DOMAIN/fullchain.pem
  rsync -e 'ssh -i /home/certbot/.ssh/id_rsa' -L $RENEWED_LINEAGE/privkey.pem certbot@$host:/etc/ssl/le/$DOMAIN/privkey.pem
done
