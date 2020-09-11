# Setup Centralized Certificate Management

## login to each web server that will host websites - as a user with sudo privileges

### create certbot user

    sudo adduser certbot

## add a firewall rule which allows ssh connections from your certificate managment server

we're assuming ufw is enabled and started
if you're not going to use a firewall, you can skip this step

    sudo ufw allow from cert.server.ip.address any port 22 proto tcp

## add the directory where you'll store certificates (example uses 'le' for Lets Encrypt)

    cd /etc/ssl
    sudo mkdir le
    sudo chown root:certbot le
    sudo chmod 775 le

## you'll need to make sure these apache modules are enabled

    cd /etc/apache2/mods-enabled
    ls -l

### enable modules that aren't already enabled

    sudo ln -s ../mods-available/rewrite.load rewrite.load
    sudo ln -s ../mods-enabled/ssl.conf ssl.conf
    sudo ln -s ../mods-enabled/ssl.load ssl.load
    sudo ln -s ../mods-enabled/socache_shmcb.load socache_shmcb.load
    sudo ln -s ../mods-enabled/socache_dbm.load socache_dbm.load

## create the options-ssl.conf file, if it doesn't already exist

adjust SSLProtocols, SSLCipherSuites, and other options as desired

    cd ..
    sudo nano options-ssl.conf

copy this into the file

    SSLEngine on
    
    # Intermediate configuration, tweak to your needs
    SSLProtocol             all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite          TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    SSLHonorCipherOrder     off

    SSLUseStapling On
    SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"

save the file and close it

## login to your TLS management server as a user with sudo privileges

### create a certbot user

    sudo adduser certbot

logout of current session, and log back in as the certbot user

## create an ssh key pair, for remote access to your webserver(s)

    ssh-keygen -t rsa

copy key to remote webserver(s)

    ssh-copy-id certbot@remote-ip-address

you should get the below output. Answer the question with 'yes', and enter the certbot user password when prompted

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

then try connecting to the remote server

    ssh 'certbot@remote-ip'

enter the certbot user's password and you should be logged in (you may not need to enter password)
now type exit to close the session
then connect again, and you shouldn't be prompted for the password this time

### when doing ssh 'certbot@remote-ip' and you get something like

    The authenticity of host 'hostname (remote-ip-address)' can't be established.
    ECDSA key fingerprint is SHA256:lrnbFX161VYPM+Q2OvSIWBf1Um1GKUWirSloWKrXbYE.
    Are you sure you want to continue connecting (yes/no)? yes
    Failed to add the host to the list of known hosts (/home/certbot/.ssh/known_hosts).
    Load key "/home/certbot/.ssh/id_rsa": Permission denied

then try this:

    sudo -i
    cd /home/certbot
    chown -R certbot:certbot .ssh
    exit
    ssh 'certbot@remote-ip'

## setup TLS management server

### open ssh session to server as a user who has sudo privileges

install nginx

    sudo apt install nginx

enable request limit of 1 request per second - or whatever you prefer

    cd /etc/nginx
    sudo nano nginx.conf

somewhere in http { }, insert:

    ##
    # Rate Limit
    ##
    
    limit_req_zone $binary_remote_addr zone=default:1m rate=1r/s;

save and close file

### setup acme-challenge site for Lets Encrypt http challenges

    cd sites-available
    sudo nano acme-challenge.example.com
    server {
      listen 80;
      server_name acme-challenge.example.com;
      root /usr/share/nginx/html;
      location ^~ /.well-known/ {
        limit_req zone=default;
        try_files $uri $uri/ =404;
      }
      location / {
        return 404;
      }
    }

### setup deploy scripts

download scripts from the [GitHub](https://github.com/endeavorcomm/le-cms) repo

copy contents of deploy-site.sh to the home directory of a user with sudo privileges, on your webserver(s)
login as that user and make sure the script is executable

    chmod 774 deploy-site.sh

copy contents of deploy-cert.sh and renew-cert.sh scripts to the home directory of the certbot user, on your certificate managment server
login as the certbot user and make sure the scripts are executable

    chmod 774 deploy-cert.sh
    chmod 774 renew-cert.sh

The system should now be ready to deploy certificates! Find next steps in deploy-certificates.md in the repo
