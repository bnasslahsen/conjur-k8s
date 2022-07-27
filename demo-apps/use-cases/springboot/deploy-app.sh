#!/bin/bash

set -a
source "./../../../.env"
set +a

kubectl config set-context --current --namespace="$APP_NAMESPACE"

kubectl delete secret springboot-credentials --ignore-not-found=true

kubectl create secret generic springboot-credentials  \
        --from-literal=conjur-authn-api-key="$CONJUR_AUTHN_API_KEY"  \
        --from-literal=conjur-account="$CONJUR_ACCOUNT" \
        --from-literal=conjur-authn-login="$CONJUR_AUTHN_LOGIN" \
        --from-literal=conjur-appliance-url="$CONJUR_APPLIANCE_URL"  \
        --from-literal=conjur-cert-file="$CONJUR_CERT_FILE"

openssl s_client -connect "$CONJUR_MASTER_HOSTNAME":"$CONJUR_MASTER_PORT" \
  -showcerts </dev/null 2> /dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print $0}' \
  > "$CONJUR_SSL_CERTIFICATE"

kubectl delete secret conjur-ssl-cert --ignore-not-found=true

kubectl create secret generic conjur-ssl-cert  \
        --from-file "$CONJUR_SSL_CERTIFICATE"

# DEPLOYMENT
envsubst < deployment.yml | kubectl replace --force -f -
if ! kubectl wait deployment "$APP_SPRINGBOOT" --for condition=Available=True --timeout=90s
  then exit 1
fi

kubectl get services "$APP_SPRINGBOOT"
kubectl get pods

rm "$CONJUR_SSL_CERTIFICATE"
