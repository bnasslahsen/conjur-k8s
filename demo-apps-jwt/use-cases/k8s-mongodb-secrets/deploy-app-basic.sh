#!/bin/bash

set -a
source "./../../../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

# DB SECRETS
envsubst < k8s-secrets.yml | $KUBE_CLI replace --force -f -

# DEPLOYMENT
envsubst < deployment.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_NAME_BASIC_MONGODB" --for condition=Available=True --timeout=90s
  then exit 1
fi

$KUBE_CLI get services "$APP_NAME_BASIC_MONGODB"
$KUBE_CLI get pods
