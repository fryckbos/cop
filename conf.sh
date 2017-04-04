#!/bin/bash

# VERSION and REGISTRY are provided by CoScale, don't change these.
export VERSION="3.8.1"
export REGISTRY=docker.coscale.com

# Fill in the registry username and password provided by CoScale.
export REGISTRY_USERNAME=
export REGISTRY_PASSWORD=
export REGISTRY_EMAIL=

# Choose a user (has to be a valid email address) and password for the super user.
export API_SUPER_USER=
export API_SUPER_PASSWD=

# Fill in the URL to access the CoScale API. Eg. API_URL=http://coscale.yourcompany.com
export API_URL=
# Fill in the URL to access the CoScale UI. Eg. APP_URL=http://coscale.yourcompany.com
export APP_URL=
# Fill in the URL to send RUM data to CoScale: RUM_URL has no protocol. Eg. RUM_URL=coscale.mycompany.com
export RUM_URL=

# Set ENABLE_HTTPS to 1 to use HTTPS. Place your certificates and private key in data/ssl/https.pem
export ENABLE_HTTPS=0

# Provide a valid email server configuration below
export MAIL_SERVER=cmail.coscale.com
export MAIL_PORT=25
export MAIL_SSL=false
export MAIL_AUTH=false
export MAIL_USERNAME=
export MAIL_PASSWORD=

# Fill in the email address from which CoScale emails will be sent.
export FROM_EMAIL=dummy@coscale.com

# Fill in the email address of the CoScale administrator below.
export SUPPORT_EMAIL=dummy@coscale.com
export ANOMALY_EMAIL=dummy@coscale.com
