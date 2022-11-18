#!/bin/bash

set -a
source "./../../../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

# DEPLOYMENT
envsubst < deployment.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_NAME" --for condition=Available=True --timeout=90s
  then exit 1
fi

$KUBE_CLI get services "$APP_NAME"
$KUBE_CLI get pods
