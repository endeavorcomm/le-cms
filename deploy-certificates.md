# Deploying TLS Certificates

Disclaimer: Restarting the webserver is involved in this process

Ensure that all DNS entries for your url are resolvable before deploying a new site and certificate

## HTTP/S site & certificate setup

SSH to your webserver(s) as a user with sudo privileges

Run the deploy-site.sh script on each server, then follow prompts

    sudo ./deploy-site.sh

When prompted by the deploy-site.sh script, SSH to your certificate management server as user certbot

Run the deploy-cert.sh script
-d is the domain name of the certificate
-h is the ip address of the webserver host(s) to copy certificate files to. Use multiple -h statements for multiple servers

    sudo ./deploy-cert.sh -d portal.example.com -h 10.1.1.1 -h 10.1.1.2

You'll be prompted to enter certbot's password once

(The next two steps will be repeated based on the number of hosts you provided in the deploy-site command)
Then accept the server's fingerprint by responding 'yes'
Then you'll be prompted to enter certbot's password again

Go back to the webserver SSH session(s)
Press the 'y' key to continue the scripts

When the script is finished, double-check redirection and validate certificate with a web browser

## Setup cronjob to renew certificate

Go back to the certificate management server SSH session
Edit certbot's crontab

    crontab -e

Copy and paste the below line to the bottom of the existing cron list. Then change the domain and host IP(s) (adjust time as desired, default is everyday at 5:00am)
Save and close the file

    0 5 * * * sudo certbot -q renew --cert-name portal.example.com --deploy-hook 'sudo /home/certbot/renew-cert.sh -h 10.1.1.1 -h 10.2.2.2'
