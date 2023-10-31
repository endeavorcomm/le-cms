#!/usr/bin/env bash
HOSTS=''
HOSTGROUP=''
hosts_declared=false
hostgroup_declared=false

while getopts "h:g:s" opt; do
  case $opt in
    h)
      HOSTS="$OPTARG"
      hosts_declared=true
      ;;
    g)
      if [[ "$hosts_declared" == true ]]
      then
        printf "Error: -h and -g cannot be used together.\n" && exit 1
      else
        HOSTGROUP="$OPTARG"
        hostgroup_declared=true
      fi
      ;;
    \?)
      printf "Invalid option -$OPTARG" && exit 1
      ;;
    :)
      printf "Argument required but missing for option -$OPTARG\n" && exit 1
      ;;
  esac
done

# check for host or hostgroup argument
if [[ $HOSTS == '' && $HOSTGROUP == '' ]]
then
  printf "Please include either -h or -g with an appropriate argument.\n"
  exit 1
fi

# determine if using hosts or hostgroup and assign to 'hosts'
if [[ $HOSTS != '' ]]
then
  IFS=", " read -ra hosts <<< $HOSTS
elif [[ $HOSTGROUP != '' && -f "./le-cms-hostgroup-$HOSTGROUP" ]]
then
  hosts=()
  while IFS= read -r line
  do
    hosts+=("$line")
  done < "le-cms-hostgroup-$HOSTGROUP"
else
  printf "No hosts or group found. If using a hostgroup, ensure the file exists.\n"
  exit 1
fi

# assign domain name for renewed cert
DOMAIN=$(basename $RENEWED_LINEAGE)

for host in "${hosts[@]}"; do
  rsync -e 'ssh -i /home/certbot/.ssh/id_rsa' -L $RENEWED_LINEAGE/cert.pem certbot@$host:/etc/ssl/le/$DOMAIN/cert.pem
  rsync -e 'ssh -i /home/certbot/.ssh/id_rsa' -L $RENEWED_LINEAGE/chain.pem certbot@$host:/etc/ssl/le/$DOMAIN/chain.pem
  rsync -e 'ssh -i /home/certbot/.ssh/id_rsa' -L $RENEWED_LINEAGE/fullchain.pem certbot@$host:/etc/ssl/le/$DOMAIN/fullchain.pem
  rsync -e 'ssh -i /home/certbot/.ssh/id_rsa' -L $RENEWED_LINEAGE/privkey.pem certbot@$host:/etc/ssl/le/$DOMAIN/privkey.pem
done
