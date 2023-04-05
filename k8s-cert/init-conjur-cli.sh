#!/bin/bash

set -a
source "./../.env"
set +a

# Global Variables
conjurURL=$CYBERARK_CONJUR_MASTER_HOSTNAME:$CYBERARK_CONJUR_MASTER_PORT
conjurAccount=$CYBERARK_CONJUR_ACCOUNT
conjurUser=admin
conjurPassword="$(cat admin_password)"

# Init Conjur CLI
echo "Init Conjur CLI"
echo "------------------------------------"
set -x
printf 'yes\nyes\nyes\nyes' | conjur init --url https://$conjurURL --account $conjurAccount
set +x
# Login to Conjur CLI
conjur login -i $conjurUser -p $conjurPassword
