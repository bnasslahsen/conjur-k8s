#!/bin/bash

set -a
source "./../../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$CYBERARK_CONJUR_NAMESPACE"

$KUBE_CLI delete configmap conjur-connect --ignore-not-found=true
FOLLOWER_URL="https://$FOLLOWER_SERVICE_NAME.$CYBERARK_CONJUR_NAMESPACE.svc.cluster.local"
if "$USE_K8S_FOLLOWER" ; then
  APPLIANCE_URL=$FOLLOWER_URL
else
  APPLIANCE_URL=$CYBERARK_CONJUR_APPLIANCE_URL
fi
openssl s_client -connect "$CYBERARK_CONJUR_MASTER_HOSTNAME":"$CYBERARK_CONJUR_MASTER_PORT" \
  -showcerts </dev/null 2> /dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print $0}' \
  > "$CYBERARK_CONJUR_SSL_CERTIFICATE"
$KUBE_CLI create configmap conjur-connect \
  --from-literal CYBERARK_CONJUR_ACCOUNT="$CYBERARK_CONJUR_ACCOUNT" \
  --from-literal CYBERARK_CONJUR_APPLIANCE_URL="$CYBERARK_CONJUR_APPLIANCE_URL" \
  --from-literal CYBERARK_CONJUR_AUTHN_URL="$APPLIANCE_URL"/authn-k8s/"$CYBERARK_CONJUR_AUTHENTICATOR_ID" \
  --from-literal AUTHENTICATOR_ID="$CYBERARK_CONJUR_AUTHENTICATOR_ID" \
  --from-literal CYBERARK_CONJUR_AUTHENTICATOR_ID="$CYBERARK_CONJUR_AUTHENTICATOR_ID" \
  --from-literal CYBERARK_CONJUR_AUTHN_LOGIN="$APP_HOST_ID"  \
  --from-file "CYBERARK_CONJUR_SSL_CERTIFICATE=$CYBERARK_CONJUR_SSL_CERTIFICATE"
rm "$CYBERARK_CONJUR_SSL_CERTIFICATE"

helm uninstall cyberark-sidecar-injector
helm repo add cyberark https://cyberark.github.io/helm-charts

helm --namespace "$CYBERARK_CONJUR_NAMESPACE" \
 install cyberark-sidecar-injector cyberark/cyberark-sidecar-injector --version 0.2.0-alpha \
 -f values.yaml  \
 --set "deploymentApiVersion=apps/v1" \
 --set "caBundle=$(kubectl -n kube-system \
   get configmap \
   extension-apiserver-authentication \
   -o=jsonpath='{.data.client-ca-file}' \
 )"

sleep 10

kubectl certificate approve cyberark-sidecar-injector."$CYBERARK_CONJUR_NAMESPACE"

