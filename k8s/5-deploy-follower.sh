#!/bin/bash

set -a
source "./../.env"
set +a

kubectl config set-context --current --namespace="$CONJUR_NAMESPACE"

# Follower Config
openssl s_client -connect "$CONJUR_MASTER_HOSTNAME":"$CONJUR_MASTER_PORT" \
  -showcerts </dev/null 2> /dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print $0}' \
  > "$CONJUR_SSL_CERTIFICATE"
kubectl delete configmap conjur-cert --ignore-not-found=true
kubectl create configmap conjur-cert --from-file=conjur.pem="$CONJUR_SSL_CERTIFICATE"
kubectl delete configmap conjur-config --ignore-not-found=true
kubectl create configmap conjur-config --from-file=conjur.yml=policies/conjur.yml

envsubst < manifests/follower-deployment-decomposed.yml | kubectl replace --force -f -
if ! kubectl wait deployment $FOLLOWER_SERVICE_NAME --for condition=Available=True --timeout=120s
  then exit 1
fi

rm "$CONJUR_SSL_CERTIFICATE"