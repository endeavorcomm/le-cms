#!/usr/bin/bash

printf "\nReady to check HTTP and HTTPS sites.\n\n"
read -p "Please enter the domain name, then press enter: " DOMAIN

## Format DOMAIN in all lowercase
DOMAIN=$(printf $DOMAIN | tr "{A-Z}" "{a-z}")

## Confirm domain name
printf "\n"
read -n1 -rsp "Is this the correct domain? $DOMAIN [Y|N] " CONFIRM

## Format response in all uppercase
CONFIRM=$(printf $CONFIRM | tr "{y}" "{Y}")

if [[ $CONFIRM == Y ]]
then
# check if http permanently redirects to https
curl -sSLI --stderr httpstatus http://$DOMAIN > httpstatus

awk 'BEGIN {
        RS="\n"
}
/^HTTP/{
    if ((NR == 1) && ($2 == 301)) {
      printf("%s %s\n", "\nHTTP redirecting to HTTPS - OK: status", $2)
    } else if (NR != 1) {
      # ignore other HTTP sections
    } else {
      printf("%s %s\n", "\nHTTP redirecting to HTTPS - FAILED: status", $2 ", expecting 301")
    }
} ' httpstatus

# check for typical errors
awk 'BEGIN {
        RS="\n"
}
/^curl/{
  if ((NR == 1) && ($2 == "(6)")) {
    printf("%s\n", "\nHTTP redirecting to HTTPS - FAILED: Could not resolve host")
  } else if ((NR == 1) && ($2 == "(60)")) {
    printf("%s\n", "\nHTTP redirecting to HTTPS - OK")
  }
} ' httpstatus

rm -f httpstatus


# check if https is responding
curl -sSI --stderr httpstatus https://$DOMAIN > httpstatus

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
} ' httpstatus

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
} ' httpstatus

rm -f httpstatus
else
  printf "\nCancelling...\n"
  exit 0
fi
