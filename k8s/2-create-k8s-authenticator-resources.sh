#!/bin/bash

set -a
source "./../.env"
set +a

$KUBE_CLI delete namespace "$CONJUR_NAMESPACE" --ignore-not-found=true
$KUBE_CLI delete clusterrole "$CONJUR_CLUSTER_ROLE_NAME" --ignore-not-found=true
$KUBE_CLI create namespace "$CONJUR_NAMESPACE"
$KUBE_CLI config set-context --current --namespace="$CONJUR_NAMESPACE"

if ! "$USE_K8S_FOLLOWER"; then
  $KUBE_CLI create serviceaccount "$CONJUR_SERVICE_ACCOUNT_NAME"
  openssl s_client -connect "$CONJUR_MASTER_HOSTNAME":"$CONJUR_MASTER_PORT" \
    -showcerts </dev/null 2> /dev/null | \
    awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print $0}' \
    > "$CONJUR_SSL_CERTIFICATE"
  $KUBE_CLI create configmap conjur-configmap \
    --from-literal authnK8sAuthenticatorID="$CONJUR_AUTHENTICATOR_ID" \
    --from-literal authnK8sClusterRole="$CONJUR_CLUSTER_ROLE_NAME" \
    --from-literal authnK8sNamespace="$CONJUR_NAMESPACE" \
    --from-literal authnK8sServiceAccount="$CONJUR_SERVICE_ACCOUNT_NAME" \
    --from-literal conjurAccount="$CONJUR_ACCOUNT" \
    --from-literal conjurApplianceUrl="$CONJUR_APPLIANCE_URL" \
    --from-literal conjurSslCertificateBase64="$(cat $CONJUR_SSL_CERTIFICATE | base64)" \
    --from-file conjurSslCertificate="$CONJUR_SSL_CERTIFICATE"
  rm "$CONJUR_SSL_CERTIFICATE"
else
  # Deploy the follower
  if "$IS_OCP" ; then
    envsubst < manifests/follower-operator-subscription.yml | $KUBE_CLI replace --force -f -
    envsubst < manifests/follower-operator-group.yml | $KUBE_CLI replace --force -f -
  else
    # Install the operator
    envsubst < manifests/follower-crds.yml | $KUBE_CLI replace --force -f -
    envsubst < manifests/follower-operator.yml | $KUBE_CLI replace --force -f -
    if ! $KUBE_CLI wait deployment "conjur-follower-operator-controller-manager" --for condition=Available=True --timeout=60s
      then exit 1
    fi
  fi
  $KUBE_CLI create serviceaccount "$CONJUR_SERVICE_ACCOUNT_NAME"
fi

envsubst < manifests/service-account-role.yml | $KUBE_CLI replace --force -f -

