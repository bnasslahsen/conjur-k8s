#!/bin/bash

set -a
source "./../../../../.env"
set +a

kubectl config set-context --current --namespace="$APP_NAMESPACE"

kubectl delete serviceaccount $APP_NAME-secretless-sa --ignore-not-found=true
kubectl create serviceaccount $APP_NAME-secretless-sa

# DB SECRETLESS CONFIGMAP
kubectl delete configmap secretless-config-mysql --ignore-not-found=true
kubectl delete configmap conjur-connect-secretless --ignore-not-found=true

kubectl create configmap secretless-config-mysql  --from-file=secretless.yml

kubectl create configmap conjur-connect-secretless \
  --from-literal SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/demo-db \
  --from-literal SPRING_DATASOURCE_USERNAME=dummy \
  --from-literal SPRING_DATASOURCE_PASSWORD=dummy \
  --from-literal SPRING_MAIN_CLOUD_PLATFORM=NONE

# APP DEPLOYMENT
envsubst < deployment.yml | kubectl replace --force -f -
if ! kubectl wait deployment $APP_NAME-secretless --for condition=Available=True --timeout=90s
  then exit 1
fi

kubectl get services $APP_NAME-secretless
kubectl get pods
