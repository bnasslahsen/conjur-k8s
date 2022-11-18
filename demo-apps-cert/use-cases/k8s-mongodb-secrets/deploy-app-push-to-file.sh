#!/bin/bash

set -a
source "./../../../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

$KUBE_CLI delete configmap spring-boot-templates --ignore-not-found=true
$KUBE_CLI create configmap spring-boot-templates --from-file=test-app.tpl

# DEPLOYMENT
envsubst < deployment-push-to-file.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_MONGO_PUSH_FILE_SIDECAR" --for condition=Available=True --timeout=90s
  then exit 1
fi

$KUBE_CLI get services "$APP_MONGO_PUSH_FILE_SIDECAR"
$KUBE_CLI get pods
