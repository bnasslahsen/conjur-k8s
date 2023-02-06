#!/bin/bash

set -a
source "./../../../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

# DB DEPLOYMENT
envsubst < db.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_DB_NAME_MYSQL" --for condition=Available=True --timeout=120s
  then exit 1
fi

# DB SECRETS
kubectl delete secret db-credentials --ignore-not-found=true
kubectl create secret generic db-credentials \
    --from-literal=url=mysql://"$APP_DB_NAME_MYSQL"."$APP_NAMESPACE".svc.cluster.local:3306/"$APP_MYSQL_DB" \
    --from-literal=username="$APP_MYSQL_USER" \
    --from-literal=password="$APP_MYSQL_PASSWORD"

# DEPLOYMENT
envsubst < deployment.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_NAME" --for condition=Available=True --timeout=90s
  then exit 1
fi

$KUBE_CLI get services "$APP_NAME"
$KUBE_CLI get pods
