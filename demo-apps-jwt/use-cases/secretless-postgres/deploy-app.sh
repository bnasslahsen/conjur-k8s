#!/bin/bash

set -a
source "./../../../.env"
set +a

#oc adm policy add-scc-to-user anyuid system:serviceaccount:$APP_NAMESPACE:$APP_SERVICE_ACCOUNT_NAME
#oc adm policy add-scc-to-user anyuid system:serviceaccount:bnl-test-app-namespace:test-app-sa
#https://docs.openshift.com/container-platform/3.11/admin_guide/manage_scc.html
$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

# DB SECRETLESS CONFIGMAP
$KUBE_CLI delete configmap secretless-config --ignore-not-found=true
envsubst < secretless.template.yml > secretless.yml
$KUBE_CLI create configmap secretless-config --from-file=secretless.yml
rm secretless.yml

# DB DEPLOYMENT
envsubst < db.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_DB_NAME_POSTGRESQL" --for condition=Available=True --timeout=120s
  then exit 1
fi

# APP DEPLOYMENT
envsubst < deployment.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_NAME_SECRETLESS" --for condition=Available=True --timeout=90s
  then exit 1
fi

$KUBE_CLI get services "$APP_NAME_SECRETLESS"
$KUBE_CLI get pods
