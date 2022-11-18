#!/bin/bash

set -a
source "./../../../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

# DB DEPLOYMENT
envsubst < db.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_DB_NAME_MONGODB" --for condition=Available=True --timeout=120s
  then exit 1
fi

#mongosh --username test --authenticationDatabase admin --password NEWPASSWORD
#use admin
#db.changeUserPassword("test", "NEWPASSWORD1")
