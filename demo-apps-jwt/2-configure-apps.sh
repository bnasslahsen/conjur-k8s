#!/bin/bash

set -a
source "./../.env"
set +a

#1- Kubernetes cluster admin -  Prepare the application namespace
$KUBE_CLI delete configmap conjur-connect --ignore-not-found=true
#$KUBE_CLI delete namespace "$APP_NAMESPACE" --ignore-not-found=true
$KUBE_CLI create namespace "$APP_NAMESPACE"

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

FOLLOWER_URL="https://$FOLLOWER_SERVICE_NAME.$CYBERARK_CONJUR_NAMESPACE.svc.cluster.local"
if "$USE_K8S_FOLLOWER" ; then
  APPLIANCE_URL=$FOLLOWER_URL
  export CYBERARK_CONJUR_APP_SERVICE_ACCOUNT_NAME=$FOLLOWER_SERVICE_ACCOUNT_NAME
else
  APPLIANCE_URL=$CYBERARK_CONJUR_APPLIANCE_URL
  export CYBERARK_CONJUR_APP_SERVICE_ACCOUNT_NAME=$CYBERARK_CONJUR_SERVICE_ACCOUNT_NAME
fi

openssl s_client -connect "$CYBERARK_CONJUR_MASTER_HOSTNAME":"$CYBERARK_CONJUR_MASTER_PORT" \
  -showcerts </dev/null 2> /dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print $0}' \
  > "$CYBERARK_CONJUR_SSL_CERTIFICATE"

$KUBE_CLI create configmap conjur-connect \
  --from-literal CONJUR_ACCOUNT="$CYBERARK_CONJUR_ACCOUNT" \
  --from-literal CONJUR_APPLIANCE_URL="$APPLIANCE_URL" \
  --from-literal CONJUR_AUTHN_URL="$APPLIANCE_URL"/authn-jwt/"$CYBERARK_CONJUR_AUTHENTICATOR_ID" \
  --from-literal AUTHENTICATOR_ID="$CYBERARK_CONJUR_AUTHENTICATOR_ID" \
  --from-literal CONJUR_AUTHN_JWT_SERVICE_ID="$CYBERARK_CONJUR_AUTHENTICATOR_ID" \
  --from-literal MY_POD_NAMESPACE="$APP_NAMESPACE"\
  --from-file "CONJUR_SSL_CERTIFICATE=$CYBERARK_CONJUR_SSL_CERTIFICATE"

rm "$CYBERARK_CONJUR_SSL_CERTIFICATE"


