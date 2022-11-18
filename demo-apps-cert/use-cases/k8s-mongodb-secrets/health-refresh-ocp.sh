#!/bin/sh

if [ ! -f /conjur/status/CONJUR_SECRETS_PROVIDED ]; then
   exit 1
fi

cd "$(dirname "$0")"
if [ -f ./CONJUR_SECRETS_UPDATED ]; then
    rm ./CONJUR_SECRETS_UPDATED
    curl -X POST --header 'Content-Type:application/json' 'http://localhost:8080/actuator/refresh'
fi