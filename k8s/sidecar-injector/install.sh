#!/bin/bash

set -a
source "./../../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$CONJUR_NAMESPACE"

$KUBE_CLI delete configmap conjur-connect --ignore-not-found=true
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
$KUBE_CLI create configmap conjur-connect \
  --from-literal CONJUR_ACCOUNT="$CONJUR_ACCOUNT" \
  --from-literal CONJUR_APPLIANCE_URL="$CONJUR_APPLIANCE_URL" \
  --from-literal CONJUR_AUTHN_URL="$APPLIANCE_URL"/authn-k8s/"$CONJUR_AUTHENTICATOR_ID" \
  --from-literal AUTHENTICATOR_ID="$CONJUR_AUTHENTICATOR_ID" \
  --from-literal CONJUR_AUTHENTICATOR_ID="$CONJUR_AUTHENTICATOR_ID" \
  --from-literal CONJUR_AUTHN_LOGIN="$APP_HOST_ID"  \
  --from-file "CONJUR_SSL_CERTIFICATE=$CONJUR_SSL_CERTIFICATE"
rm "$CONJUR_SSL_CERTIFICATE"

helm uninstall cyberark-sidecar-injector
helm repo add cyberark https://cyberark.github.io/helm-charts

helm --namespace "$CONJUR_NAMESPACE" \
 install cyberark-sidecar-injector cyberark/cyberark-sidecar-injector --version 0.2.0-alpha \
 -f values.yaml  \
 --set "deploymentApiVersion=apps/v1" \
 --set "caBundle=$(kubectl -n kube-system \
   get configmap \
   extension-apiserver-authentication \
   -o=jsonpath='{.data.client-ca-file}' \
 )"

sleep 10

kubectl certificate approve cyberark-sidecar-injector."$CONJUR_NAMESPACE"

