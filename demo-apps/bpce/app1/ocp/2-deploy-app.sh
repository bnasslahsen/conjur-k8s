#!/bin/bash

set -a
source "./../config"
set +a

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

# SUMMON CONFIGMAP
$KUBE_CLI delete configmap summon-config-init --ignore-not-found=true
envsubst < secrets.template.yml > secrets.yml
$KUBE_CLI create configmap summon-config-init --from-file=secrets.yml
rm secrets.yml

# DEPLOYMENT
envsubst < deployment.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_NAME" --for condition=Available=True --timeout=90s
  then exit 1
fi

$KUBE_CLI get services "$APP_NAME"
$KUBE_CLI get pods
