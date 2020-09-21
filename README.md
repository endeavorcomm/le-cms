# Centralized Lets Encrypt Certificate Management

Deploy and renew TLS certificates from a central server.

Supports HTTP challenges natively. Supports DNS challenges using [acme-dns](https://github.com/joohoi/acme-dns) and joohoi's [acme-dns-certbot](https://github.com/joohoi/acme-dns-certbot-joohoi).

## Prerequsites

- a Linux server for managing certificates, with [Certbot](https://certbot.eff.org/instructions) installed
- at least one Linux server for hosting websites
- a DNS entry for the certificate management server domain name
- at least one DNS entry for the web server which will use the Lets Encrypt certificate
- ssh access to all servers

### Our documentation is based on the following environment

- a modern version of Ubuntu on all servers
- apache2 installed on the webserver(s)
- nginx installed on the certificate management server
- a user on each server who has sudo or root privileges
- acme-challenge.example.com as the domain for the certificate management server
- portal.example.com as the domain name for our website using the certificate

Adjust as neccessary for your choice of linux distributions and software.

## Network Diagrams

This is a basic view of the certificate management using HTTP challenges
![TLS HTTP Flow](./tls-flow-http.gif)

### Brief Explanation of HTTP Flow

1. Using the deploy-cert script, the management server will request a certificate for portal.example.com from Lets Encrypt
2. Lets Encrypt performs a DNS lookup for portal.example.com. Let's assume there are two DNS A records for portal.example.com in DNS - 10.1.1.1 and 10.2.2.2
3. Lets Encrypt will make an http request to one of the IP addresses from the DNS response
4. The webserver which receives the request will respond with a 301 redirect
    - Lets Encrypt honors the 301 redirect and sends the http request to the certificate management server
    - The certificate management server responds to the http challenge, Lets Encrypt validates the response and issues the certificate to the management server
    - The certbot client stores the files locally
5. The deploy-cert script finishes by copying the locally-stored certificate files to the webservers

This is a basic view of the certificate management using HTTP challenges
![TLS DNS Flow](./tls-flow-dns.gif)

### Brief Explanation of DNS Flow

1. Using the deploy-cert script, the management server will request a certificate for portal.example.com from Lets Encrypt
2. Lets Encrypt performs a DNS lookup for portal.example.com. Let's assume there are two DNS A records for portal.example.com in DNS - 10.1.1.1 and 10.2.2.2
3. acme-dns-auth.py will register an account with the acme-dns server
    - the acme-dns server creates a txt record for the domain
    - you're prompted to create a CNAME record on your main DNS server for _acme-challenge.portal.example.com that points to acme-challenge.example.com
    - Lets Encrypt initiates a DNS challenge, the acme-dns server responds, Lets Encrypt validates the response and issues the certificate to the managment server
    - The certbot client stores the files locally
4. The deploy-cert script finishes by copying the locally-stored certificate files to the webservers

## Script file placement

deploy-site.sh should be copied to the webserver(s)

deploy-cert.sh and renew-cert.sh should be copied to the certificate management server

## Setup the Certificate Management System

Once you have the prerequsites taken care of, follow the steps found in setup-cert-mgmt-system.md

## Start deploying certificates

Steps can be found in deploy-certificates.md

## Extras

The verify-http.sh script can be used to make sure that http is redirecting to https, https is responding, and the domain name matches the certificate.
This process is automatically done during site deployment. But if the verifications fail during that time, you can correct the errors and run this script to only test the verifications.
