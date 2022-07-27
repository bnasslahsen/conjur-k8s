#!/bin/bash

set -a
source "./../../../.env"
set +a

#oc adm policy add-scc-to-user anyuid system:serviceaccount:$APP_NAMESPACE:$APP_SERVICE_ACCOUNT_NAME
#https://docs.openshift.com/container-platform/3.11/admin_guide/manage_scc.html
kubectl config set-context --current --namespace="$APP_NAMESPACE"

# DB SECRETLESS CONFIGMAP
kubectl delete configmap secretless-config --ignore-not-found=true
envsubst < secretless.template.yml > secretless.yml
kubectl create configmap secretless-config --from-file=secretless.yml
rm secretless.yml


# Service account role binding
envsubst < service-account-role.yml | kubectl replace --force -f -

# DB DEPLOYMENT
envsubst < db.yml | kubectl replace --force -f -
if ! kubectl wait deployment "$APP_DB_NAME" --for condition=Available=True --timeout=120s
  then exit 1
fi

# APP DEPLOYMENT
envsubst < deployment.yml | kubectl replace --force -f -
if ! kubectl wait deployment "$APP_NAME_SECRETLESS" --for condition=Available=True --timeout=90s
  then exit 1
fi

kubectl get services "$APP_NAME_SECRETLESS"
kubectl get pods
