# Setup Centralized Certificate Management

## Setup servers that will host websites

Login as a user with sudo privileges, then create the certbot user. You'll need to remember the password for steps further below

    sudo adduser certbot

Add a firewall rule which allows ssh connections from your certificate managment server

We're assuming ufw is enabled and started. If you're not going to use a firewall, you can skip this step

    sudo ufw allow from cert.server.ip.address any port 22 proto tcp

Add the directory where you'll store certificates

    cd /etc/ssl
    sudo mkdir le
    sudo chown root:certbot le
    sudo chmod 775 le

### If you're using Apache2 for HTTP challenges

Make sure relevant apache modules are enabled

    cd /etc/apache2/mods-enabled

    sudo ln -s ../mods-available/rewrite.load rewrite.load
    sudo ln -s ../mods-available/ssl.conf ssl.conf
    sudo ln -s ../mods-available/ssl.load ssl.load
    sudo ln -s ../mods-available/socache_shmcb.load socache_shmcb.load
    sudo ln -s ../mods-available/socache_dbm.load socache_dbm.load

Create the options-ssl.conf file, if these don't already exist in your Apache configuration. Adjust SSLProtocols, SSLCipherSuites, and other options as desired

    cd ..
    sudo nano options-ssl.conf

Copy the below content into the file

    SSLEngine on
    
    # Intermediate configuration, tweak to your needs
    SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite          TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder     off

Save and close the file

Open the apache.conf file

    sudo nano apache.conf

Copy this into the apache.conf file

    SSLUseStapling On
    SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"

Save the file and close it

Restart Apache

    sudo systemctl reload apache2

## Setup the TLS certificate managment server

Login as a user with sudo privileges, then create the certbot user. You may want to set the password the same as the certbot user you created on your web server(s)

    sudo adduser certbot

Install nginx

    sudo apt install nginx

Save and close the file

### acme-challenge site for Lets Encrypt HTTP challenges

    cd sites-available
    sudo nano acme-challenge.example.com

Copy the below content into the file

    server {
      listen 80;
      server_name acme-challenge.example.com;
      root /usr/share/nginx/html;
      location ^~ /.well-known/ {
        try_files $uri $uri/ =404;
      }
      location / {
        return 404;
      }
    }

Save and close the file

Enable the site

    cd ../site-enabled
    sudo ln -s ../sites-available/acme-challenge.example.com acme-challenge.example.com

Restart nginx

    sudo systemctl restart nginx

Logout of current session, and log back in as the certbot user

create an ssh key pair, for remote access to your webserver(s)

    ssh-keygen -t rsa

copy the key to the remote webserver(s)

    ssh-copy-id certbot@remote-ip-address

You should get the below output. Answer the question with 'yes', and enter the webserver's certbot user password when prompted (from the 1st step of this doc)

    /usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/certbot/.ssh/id_rsa.pub"
    The authenticity of host 'hostname (remote-ip-address)' can't be established.
    ECDSA key fingerprint is SHA256:nbFX161VYPM+Q2OvWBf1Um1GKUWirSloWKrXb.
    Are you sure you want to continue connecting (yes/no)? yes
    
    /usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
    /usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
    certbot@remote-ip's password: enter password of certbot user
    
    Number of key(s) added: 1
    
    Now try logging into the machine, with:   "ssh 'certbot@remote-ip-address'"
    and check to make sure that only the key(s) you wanted were added.

Then try connecting to the remote server

    ssh 'certbot@remote-ip-address'

Enter the certbot user's password and you should be logged in (this may not be needed)
Now type exit to close the session
Then connect again, and you shouldn't be prompted for the password this time

When doing ssh 'certbot@remote-ip-address' and you get something like:

    The authenticity of host 'hostname (remote-ip-address)' can't be established.
    ECDSA key fingerprint is SHA256:lrnbFX161VYPM+Q2OvSIWBf1Um1GKUWirSloWKrXbYE.
    Are you sure you want to continue connecting (yes/no)? yes
    Failed to add the host to the list of known hosts (/home/certbot/.ssh/known_hosts).
    Load key "/home/certbot/.ssh/id_rsa": Permission denied

you can try this to resolve the issue:

    sudo -i
    cd /home/certbot
    chown -R certbot:certbot .ssh
    exit
    ssh 'certbot@remote-ip-address'

logout of 'certbot' user session

### To enable Lets Encrypt DNS challenges

Install [acme-dns](https://github.com/joohoi/acme-dns) and follow the instructions
(make sure the gcc package is installed on your server before trying to build acme-dns)

Be sure to add DNS records to your main DNS server before starting acme-dns service!!

For example, if your acme-challenge server's FQDN is acme-challenge.example.com:

- add an A record for it in your example.com DNS zone
- add an NS record for acme-challenge.example.com that points to acme-challenge.example.com

#### A few notes about the acme-dns configuration

IN THE [general] section:

- change 'listen' to the network IP address of your acme-challenge server
- change 'domain' and 'nsname' to the FQDN of your acme-challenge server
- change 'nsadmin' to a proper email address

IN THE [api] section:

- change 'ip' to the network IP address of your acme-challenge server
- change 'tls' to "letsencrypt" (this allows acme-dns to properly bind to port 443)

Install [acme-dns-client](https://github.com/joohoi/acme-dns-certbot-joohoi) and follow the instructions

The acme-dns-auth.py script uses python. If you have python3 installed, add a symbolic link

    sudo ln -s /usr/bin/python3 /usr/bin/python

#### A few notes about the acme-dns-auth.py script configuration

- change the 'ACMEDNS_URL' to the FQDN of your acme-challenge server
- add your acme-challenge server's network IP to the 'ALLOW_FROM' array (ex "192.168.1.1/32")

### Deploy le-cms scripts

If using HTTP challenges, login to your webserver(s) as a user with sudo privileges

Download scripts, or clone the repo from [GitHub](https://github.com/endeavorcomm/le-cms), and copy to the user's home directory

    sudo apt install git
    git clone https://github.com/endeavorcomm/le-cms.git

Change the !#/bin/bash line at the top of all scripts to whatever the path is to your bash. To find out, type 'which bash' in the CLI

If you cloned the repo, copy deploy-site.sh to your user's home directory

    cp le-cms/deploy-site.sh ~

Make sure the script is executable

    chmod 700 deploy-site.sh

Login to your certificate management server as the certbot user

Download scripts, or clone the repo from [GitHub](https://github.com/endeavorcomm/le-cms), and copy to the user's home directory

    sudo apt install git
    git clone https://github.com/endeavorcomm/le-cms.git

Change the !#/bin/bash line at the top of all scripts to whatever the path is to your bash. To find out, type 'which bash' in the CLI

If you cloned the repo, copy deploy-cert.sh and renew-cert.sh scripts into the home directory of the certbot user, on your certificate managment server

    cp le-cms/deploy-cert.sh ~
    cp le-cms/renew-cert.sh ~

Make sure the scripts are executable

    chmod 700 deploy-cert.sh
    chmod 700 renew-cert.sh

If you're having trouble running the scripts, try copying the contents from the repo file, then pasting into the file on the server

The system should now be ready to deploy certificates! Find next steps in deploy-certificates.md in the repo
