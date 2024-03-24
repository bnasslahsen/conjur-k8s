#!/bin/bash

set -a
source "./../../../.env"
set +a

kubectl config set-context --current --namespace="$APP_NAMESPACE"

kubectl delete serviceaccount $APP_NAME-push-to-file-sidecar-sa --ignore-not-found=true
kubectl create serviceaccount $APP_NAME-push-to-file-sidecar-sa

kubectl delete configmap spring-boot-templates --ignore-not-found=true
kubectl create configmap spring-boot-templates --from-file=$APP_NAME.tpl

# DEPLOYMENT
envsubst < deployment.yml | kubectl replace --force -f -
if ! kubectl wait deployment $APP_NAME-push-to-file-sidecar --for condition=Available=True --timeout=90s
  then exit 1
fi

kubectl get services $APP_NAME-push-to-file-sidecar
kubectl get pods