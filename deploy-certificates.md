# Deploying Certificates

Disclaimer: Restarting the webserver is involved in this process

Ensure that all DNS entries for your url are resolvable

## SSH to your webserver(s) as a user with sudo privileges

### run deploy-site.sh on each server, then follow prompts

    sudo ./deploy-site.sh

## once prompted by the deploy-site.sh script, SSH to your certificate management server as user certbot

-d is the domain name of the certificate
-h is the ip address of the webserver host(s) to copy certificate files to. Use multiple -h statements for multiple servers

    sudo ./deploy-cert.sh -d portal.example.com -h 10.1.1.1 -h 10.1.1.2

you'll be prompted to enter certbot's password twice

## go back to the webserver(s) SSH session

press the 'y' key to continue the scripts

Once the script is finished, double-check redirection and validate certificate with a browser

## Setup cronjob to renew certificate

make sure you are logged into your certificate management server as the certbot user
edit certbot's crontab
    crontab -e

Change the domain name, and hosts; then copy and paste to the bottom of the existing cron list (adjust time as desired, default is everyday at 5:00am)
save and close the file

    0 5 * * * sudo certbot -q renew --cert-name portal.example.com --deploy-hook 'sudo /home/certbot/renew-cert.sh -h 10.1.1.1 -h 10.2.2.2'
