#!/usr/bin/env bash
DOMAIN=''
HOSTS=''
HOSTGROUP=''
CONFIG_DIR=/etc/le-cms
hosts_declared=false
hostgroup_declared=false

## Check for configuration file
if [[ -f "$CONFIG_DIR/cert.config" ]]
then
. $CONFIG_DIR/cert.config
else
  printf "No cert.config file found in $CONFIG_DIR. Exiting.\n"
  exit 1
fi

while getopts ":d:h:g:s" opt; do
  case $opt in
    d)
      DOMAIN="$OPTARG"
      ;;
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

# check for domain argument
if [[ $DOMAIN == '' ]]
then
  printf "Please include a domain name with -d\n"
  exit 1
fi

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
elif [[ $HOSTGROUP != '' && -f "$CONFIG_DIR/hostgroup-$HOSTGROUP" ]]
then
  hosts=()
  while IFS= read -r line
  do
    hosts+=("$line")
  done < "$CONFIG_DIR/hostgroup-$HOSTGROUP"
else
  printf "No hosts found.\n"
  exit 1
fi

BASE_DIR=/etc/letsencrypt/live/$DOMAIN

if [[ $CHALLENGE == '' ]]
then
  read -p "Use HTTP or DNS for the domain challenge [http|dns]? " CHALLENGE
fi

## Format CHALLENGE in all lowercase
CHALLENGE=$(printf $CHALLENGE | tr "{A-Z}" "{a-z}")

if [[ $CHALLENGE == http ]]
then
  printf "Requesting Lets Encrypt certificate for $DOMAIN with HTTP challenge...\n"
  sudo certbot certonly --webroot -w /usr/share/nginx/html -d $DOMAIN
elif [[ $CHALLENGE == dns ]]
then
  if [[ $ACME == '' ]]
  then
    read -p "Please enter the FQDN for the acme-dns server, then press enter: " ACME
    printf "\n"
    read -n1 -rsp "Is this correct? $ACME [Y|N] " CONFIRMSVR

    ## Format response in all uppercase
    CONFIRMSVR=$(printf $CONFIRMSVR | tr "{y}" "{Y}")

    if [[ $CONFIRMSVR != Y ]]
    then
      printf "You did not press Y. Exiting..."
      exit 0
    fi
  fi

  ## Format ACME DNS server fqdn in all lowercase
  ACME=$(printf $ACME | tr "{A-Z}" "{a-z}")

  printf "\nChecking health of acme-dns server...\n"
  curl -sSI --stderr le-cms_acmestatus -X GET https://$ACME/health > le-cms_acmestatus

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
  printf "Invalid challenge option - $CHALLENGE\n"
  exit 1
fi

printf "\nDeploying certificate...\n"
for host in "${hosts[@]}"; do
  rsync -e 'ssh -i /home/certbot/.ssh/id_rsa' -rpLgo $BASE_DIR certbot@$host:/etc/ssl/le/
done

printf "\nAdding renew hook to certificate configuration...\n"
if [[ $hosts_declared == true ]]
then
  sed -i "/\[renewalparams\]/a renew_hook = \"/home/certbot/renew-cert.sh -h '$HOSTS'\"" /etc/letsencrypt/renewal/$DOMAIN.conf
elif [[ $hostgroup_declared == true ]]
then
  sed -i "/\[renewalparams\]/a renew_hook = \"/home/certbot/renew-cert.sh -g '$HOSTGROUP'\"" /etc/letsencrypt/renewal/$DOMAIN.conf
fi

printf "\nFinished.\n"
exit 0
