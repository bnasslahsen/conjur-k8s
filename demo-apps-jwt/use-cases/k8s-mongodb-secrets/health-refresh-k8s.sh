#!/bin/sh

if [ ! -f /conjur/status/CYBERARK_CONJUR_SECRETS_PROVIDED ]; then
   exit 1
fi

cd "$(dirname "$0")"
if [ -f ./CYBERARK_CONJUR_SECRETS_UPDATED ]; then
    rm ./CYBERARK_CONJUR_SECRETS_UPDATED
    wget -O- --post-data='{}' --header='Content-Type:application/json' 'http://localhost:8080/actuator/refresh'
fi