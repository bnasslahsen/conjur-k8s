#!/bin/bash

set -a
source "./../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$CYBERARK_CONJUR_NAMESPACE"

# Follower Config
openssl s_client -connect "$CYBERARK_CONJUR_MASTER_HOSTNAME":"$CYBERARK_CONJUR_MASTER_PORT" \
  -showcerts </dev/null 2> /dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print $0}' \
  > "$CYBERARK_CONJUR_SSL_CERTIFICATE"
$KUBE_CLI delete configmap conjur-cert --ignore-not-found=true
$KUBE_CLI create configmap conjur-cert --from-file=conjur.pem="$CYBERARK_CONJUR_SSL_CERTIFICATE"
$KUBE_CLI delete configmap conjur-config --ignore-not-found=true
envsubst < policies/conjur.yml > conjur.yml.tmp
$KUBE_CLI create configmap conjur-config --from-file=conjur.yml=conjur.yml.tmp
rm conjur.yml.tmp
envsubst < manifests/follower-deployment-decomposed.yml | $KUBE_CLI replace --force -f -

rm "$CYBERARK_CONJUR_SSL_CERTIFICATE"