#!/bin/bash

set -a
source "./../.env"
set +a

#1- Kubernetes cluster admin -  Prepare the application namespace
$KUBE_CLI delete namespace "$APP_NAMESPACE" --ignore-not-found=true
$KUBE_CLI create namespace "$APP_NAMESPACE"

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"
$KUBE_CLI create serviceaccount "$APP_SERVICE_ACCOUNT_NAME"

FOLLOWER_URL="https://$FOLLOWER_SERVICE_NAME.$CONJUR_NAMESPACE.svc.cluster.local"
if "$USE_K8S_FOLLOWER" ; then
  APPLIANCE_URL=$FOLLOWER_URL
  export CONJUR_APP_SERVICE_ACCOUNT_NAME=$FOLLOWER_SERVICE_ACCOUNT_NAME
else
  APPLIANCE_URL=$CONJUR_APPLIANCE_URL
  export CONJUR_APP_SERVICE_ACCOUNT_NAME=$CONJUR_SERVICE_ACCOUNT_NAME
fi

openssl s_client -connect "$CONJUR_MASTER_HOSTNAME":"$CONJUR_MASTER_PORT" \
  -showcerts </dev/null 2> /dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print $0}' \
  > "$CONJUR_SSL_CERTIFICATE"

$KUBE_CLI create configmap conjur-connect \
  --from-literal CONJUR_ACCOUNT="$CONJUR_ACCOUNT" \
  --from-literal CONJUR_APPLIANCE_URL="$CONJUR_APPLIANCE_URL" \
  --from-literal CONJUR_AUTHN_URL="$APPLIANCE_URL"/authn-k8s/"$CONJUR_AUTHENTICATOR_ID" \
  --from-literal AUTHENTICATOR_ID="$CONJUR_AUTHENTICATOR_ID" \
  --from-file "CONJUR_SSL_CERTIFICATE=$CONJUR_SSL_CERTIFICATE"

envsubst < manifests/service-account-role.yml | $KUBE_CLI replace --force -f -

rm "$CONJUR_SSL_CERTIFICATE"


