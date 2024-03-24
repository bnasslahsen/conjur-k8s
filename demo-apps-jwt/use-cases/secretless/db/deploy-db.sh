#!/bin/bash

set -a
source "./../../../../.env"
set +a

kubectl config set-context --current --namespace="$APP_NAMESPACE"

kubectl delete serviceaccount demo-db-mysql-sa --ignore-not-found=true
kubectl create serviceaccount demo-db-mysql-sa

# Service account role binding
envsubst < service-account-role.yml | kubectl replace --force -f -
# DB SECRETS
envsubst < k8s-secrets.yml | kubectl replace --force -f -

# DB DEPLOYMENT
envsubst < db.yml | kubectl replace --force -f -
if ! kubectl wait deployment demo-db-mysql --for condition=Available=True --timeout=120s
  then exit 1
fi

kubectl get services $APP_NAME-secretless
kubectl get pods
