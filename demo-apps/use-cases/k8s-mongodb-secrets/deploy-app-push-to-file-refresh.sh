#!/bin/bash

set -a
source "./../../../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

$KUBE_CLI delete configmap spring-boot-templates-refresh --ignore-not-found=true
$KUBE_CLI create configmap spring-boot-templates-refresh --from-file=test-app.tpl

# SUMMON CONFIGMAP
$KUBE_CLI delete configmap push-to-file-refresh-config --ignore-not-found=true
$KUBE_CLI create configmap push-to-file-refresh-config --from-file=health-refresh-$KUBE_PLATFORM.sh

# DEPLOYMENT
envsubst < deployment-push-to-file-refresh.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_MONGO_PUSH_FILE_REFRESH_SIDECAR" --for condition=Available=True --timeout=90s
  then exit 1
fi

$KUBE_CLI get services "$APP_MONGO_PUSH_FILE_REFRESH_SIDECAR"
$KUBE_CLI get pods
