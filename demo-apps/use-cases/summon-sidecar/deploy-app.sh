#!/bin/bash

set -a
source "./../../../.env"
set +a

kubectl config set-context --current --namespace="$APP_NAMESPACE"

# SUMMON CONFIGMAP
kubectl delete configmap summon-config-sidecar --ignore-not-found=true
envsubst < secrets.template.yml > secrets.yml
kubectl create configmap summon-config-sidecar --from-file=secrets.yml
rm secrets.yml

# DEPLOYMENT
envsubst < deployment.yml | kubectl replace --force -f -
if ! kubectl wait deployment "$APP_SUMMON_SIDECAR" --for condition=Available=True --timeout=90s
  then exit 1
fi

kubectl get services "$APP_SUMMON_SIDECAR"
kubectl get pods
