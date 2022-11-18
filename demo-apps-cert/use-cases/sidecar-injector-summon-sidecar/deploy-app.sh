#!/bin/bash

set -a
source "./../../../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

kubectl label namespace "$APP_NAMESPACE" cyberark-sidecar-injector=enabled --overwrite true

# SUMMON CONFIGMAP
$KUBE_CLI delete configmap sidecar-injector-summon-config-sidecar --ignore-not-found=true
envsubst < secrets.template.yml > secrets.yml
$KUBE_CLI create configmap sidecar-injector-summon-config-sidecar --from-file=secrets.yml
rm secrets.yml
$KUBE_CLI delete configmap sidecar-injector-summon-sidecar-connect --ignore-not-found=true

# ADMISSION WEBHOOK CONTROLLER CONNECT MAP
FOLLOWER_URL="https://$FOLLOWER_SERVICE_NAME.$CONJUR_NAMESPACE.svc.cluster.local"
if "$USE_K8S_FOLLOWER" ; then
  APPLIANCE_URL=$FOLLOWER_URL
else
  APPLIANCE_URL=$CONJUR_APPLIANCE_URL
fi
openssl s_client -connect "$CONJUR_MASTER_HOSTNAME":"$CONJUR_MASTER_PORT" \
  -showcerts </dev/null 2> /dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print $0}' \
  > "$CONJUR_SSL_CERTIFICATE"
$KUBE_CLI create configmap sidecar-injector-summon-sidecar-connect \
  --from-literal CONJUR_ACCOUNT="$CONJUR_ACCOUNT" \
  --from-literal CONJUR_VERSION="5" \
  --from-literal CONJUR_APPLIANCE_URL="$CONJUR_APPLIANCE_URL" \
  --from-literal CONJUR_AUTHN_LOGIN="$APP_HOST_ID"  \
  --from-literal CONJUR_AUTHN_URL="$APPLIANCE_URL"/authn-k8s/"$CONJUR_AUTHENTICATOR_ID" \
  --from-literal AUTHENTICATOR_ID="$CONJUR_AUTHENTICATOR_ID" \
  --from-file "CONJUR_SSL_CERTIFICATE=$CONJUR_SSL_CERTIFICATE"
rm "$CONJUR_SSL_CERTIFICATE"

# DEPLOYMENT
envsubst < deployment.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_SIDECAR_INJECTOR_SUMMON_SIDECAR" --for condition=Available=True --timeout=90s
  then exit 1
fi

$KUBE_CLI get services "$APP_SUMMON_INIT"
$KUBE_CLI get pods
