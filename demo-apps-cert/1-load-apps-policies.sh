#!/bin/bash

set -a
source "./../.env"
set +a

#Define the application as a Conjur host in policy
envsubst < policies/app-host.yml > app-host.yml.tmp
conjur policy update -b root -f app-host.yml.tmp
rm app-host.yml.tmp

if "$USE_SYNCHRONIZER" ; then
  # Case of Secrets synchronized from the Vault
  envsubst < policies/safe-access.yml > safe-access.yml.tmp
  conjur policy update -b root -f safe-access.yml.tmp
  rm safe-access.yml.tmp
else
  # Case of Secrets in Conjur
  envsubst < policies/app-secrets.yml > app-secrets.yml.tmp
  conjur policy update -b root -f app-secrets.yml.tmp
  rm app-secrets.yml.tmp
  # Set variables
  conjur variable set -i "$APP_SECRET_URL_PATH" -v jdbc:h2:mem:testdb
  conjur variable set -i "$APP_SECRET_USERNAME_PATH" -v user
  conjur variable set -i "$APP_SECRET_PASSWORD_PATH" -v pass
  conjur variable set -i "$APP_SECRETLESS_DB_HOST_PATH" -v "$APP_DB_NAME_POSTGRESQL"."$APP_NAMESPACE".svc.cluster.local
  conjur variable set -i "$APP_SECRETLESS_DB_PORT_PATH" -v 5432
  conjur variable set -i "$APP_SECRETLESS_DB_USERNAME_PATH" -v "$APP_POSTGRESQL_USER"
  conjur variable set -i "$APP_SECRETLESS_DB_PASSWORD_PATH" -v "$APP_POSTGRESQL_PASSWORD"
  conjur variable set -i "$APP_SECRETLESS_DB_MYSQL_HOST_PATH" -v "$APP_DB_NAME_MYSQL"."$APP_NAMESPACE".svc.cluster.local
  conjur variable set -i "$APP_SECRETLESS_DB_MYSQL_PORT_PATH" -v 3306
  conjur variable set -i "$APP_SECRETLESS_DB_MYSQL_USERNAME_PATH" -v "$APP_MYSQL_USER"
  conjur variable set -i "$APP_SECRETLESS_DB_MYSQL_PASSWORD_PATH" -v "$APP_MYSQL_PASSWORD"
  conjur variable set -i "$APP_MONGO_HOST_URI" -v "$APP_MONGO_URI"
fi
