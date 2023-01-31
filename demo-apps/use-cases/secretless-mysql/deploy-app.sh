#!/bin/bash

set -a
source "./../../../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

# DB SECRETLESS CONFIGMAP
$KUBE_CLI delete configmap secretless-config-mysql --ignore-not-found=true
envsubst < secretless.template.yml > secretless.yml
$KUBE_CLI create configmap secretless-config-mysql  --from-file=secretless.yml
rm secretless.yml

# APP DEPLOYMENT
envsubst < deployment.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_NAME_SECRETLESS_MYSQL" --for condition=Available=True --timeout=90s
  then exit 1
fi

$KUBE_CLI get services "$APP_NAME_SECRETLESS_MYSQL"
$KUBE_CLI get pods
