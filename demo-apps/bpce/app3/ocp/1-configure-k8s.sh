#!/bin/bash

set -a
source "./../config"
set +a

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"
$KUBE_CLI delete serviceaccount "$APP_SERVICE_ACCOUNT_NAME" --ignore-not-found=true
$KUBE_CLI create serviceaccount "$APP_SERVICE_ACCOUNT_NAME"

openssl s_client -connect "$CONJUR_MASTER_HOSTNAME":"$CONJUR_MASTER_PORT" \
  -showcerts </dev/null 2> /dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print $0}' \
  > "$CONJUR_SSL_CERTIFICATE"

$KUBE_CLI delete configmap conjur-connect --ignore-not-found=true
$KUBE_CLI create configmap conjur-connect \
  --from-literal CONJUR_ACCOUNT="$CONJUR_ACCOUNT" \
  --from-literal CONJUR_APPLIANCE_URL="$CONJUR_APPLIANCE_URL" \
  --from-literal CONJUR_AUTHN_URL="$FOLLOWER_URL"/authn-k8s/"$CONJUR_AUTHENTICATOR_ID" \
  --from-literal AUTHENTICATOR_ID="$CONJUR_AUTHENTICATOR_ID" \
  --from-file "CONJUR_SSL_CERTIFICATE=$CONJUR_SSL_CERTIFICATE"

envsubst < service-account-role.yml | $KUBE_CLI replace --force -f -

rm "$CONJUR_SSL_CERTIFICATE"


