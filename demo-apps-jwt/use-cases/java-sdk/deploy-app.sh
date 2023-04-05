#!/bin/bash

set -a
source "./../../../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

$KUBE_CLI delete secret java-sdk-credentials --ignore-not-found=true

openssl s_client -connect "$CYBERARK_CONJUR_MASTER_HOSTNAME":"$CYBERARK_CONJUR_MASTER_PORT" \
  -showcerts </dev/null 2> /dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print $0}' \
  > "$CYBERARK_CONJUR_SSL_CERTIFICATE"

FOLLOWER_URL="https://$FOLLOWER_SERVICE_NAME.$CYBERARK_CONJUR_NAMESPACE.svc.cluster.local"
if "$USE_K8S_FOLLOWER" ; then
  APPLIANCE_URL=$FOLLOWER_URL
else
  APPLIANCE_URL=$CYBERARK_CONJUR_APPLIANCE_URL
fi

$KUBE_CLI create secret generic java-sdk-credentials  \
        --from-literal=conjur-authn-api-key="$CYBERARK_CONJUR_AUTHN_API_KEY"  \
        --from-literal=conjur-account="$CYBERARK_CONJUR_ACCOUNT" \
        --from-literal=conjur-authn-login="$CYBERARK_CONJUR_AUTHN_LOGIN" \
        --from-literal=conjur-appliance-url="$APPLIANCE_URL"  \
        --from-literal=conjur-ssl-cert-base64="$(cat $CYBERARK_CONJUR_SSL_CERTIFICATE | base64)"

# DEPLOYMENT
envsubst < deployment.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_JAVA_SDK" --for condition=Available=True --timeout=90s
  then exit 1
fi

$KUBE_CLI get services "$APP_JAVA_SDK"
$KUBE_CLI get pods

rm "$CYBERARK_CONJUR_SSL_CERTIFICATE"
