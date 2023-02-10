#!/bin/bash

set -a
source "./../config"
set +a

envsubst < app-host.yml > app-host.yml.tmp
conjur policy update -b root -f app-host.yml.tmp >> app-host.log
rm app-host.yml.tmp

envsubst < app-secrets.yml > app-secrets.yml.tmp
conjur policy update -b root -f app-secrets.yml.tmp
rm app-secrets.yml.tmp

conjur variable set -i "$APP_SECRET_URL_PATH" -v jdbc:h2:mem:testdb
conjur variable set -i "$APP_SECRET_USERNAME_PATH" -v user
conjur variable set -i "$APP_SECRET_PASSWORD_PATH" -v pass