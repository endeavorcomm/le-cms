# Deploying TLS Certificates

Disclaimer: If using the HTTP method, gracefully restarting the webserver is involved in this process

Ensure that all DNS entries for your url are resolvable before deploying a new site and certificate

## If using the HTTP challenge method

SSH to your webserver(s) as a user with sudo privileges

Run the deploy-site.sh script on each server, then follow prompts

    sudo ./deploy-site.sh

When prompted by the deploy-site.sh script, SSH to your certificate management server as user certbot

## If using the DNS challenge method, or after the above step, continue

SSH to your certificate management server as user certbot

Run the deploy-cert.sh script

-d is the domain name of the certificate, and is required.

-h is a comma-space separated list of ip addresses of the webserver host(s) to copy certificate files to, and is required. If using multiple hosts, the entire set with single quotes.

    sudo ./deploy-cert.sh -d portal.example.com -h '10.1.1.1, 10.1.1.2'

-g is a string which represents the hostgroup you want to use for this certificate. Hostgroups represent a set of IPs which the certificate will be copied to. e.g. `-g core` would require a filename called `le-cms-hostgroup-core`. The file should be in the same directory you're running the script from, and should be a list of IPs separated by a newline.

e.g. file `le-cms-hostgroup-core`
```
10.1.1.1
10.1.1.2
```

    sudo ./deploy-cert.sh -d portal.example.com -g core

Follow the prompts

You'll be prompted to enter certbot's password once

(When first deploying to these hosts, the next two steps will be repeated based on the number of hosts you provided in the deploy-site command)
Accept the server's fingerprint by responding 'yes'

## If using the HTTP challenge method

Go back to the webserver SSH session(s)
Press the 'y' key to continue the scripts

## If using the DNS challenge method

Follow the prompts to create a CNAME record for the acme challenge

## Then continue

When the script is finished, double-check redirection and validate certificate with a web browser
