#!/bin/bash

set -a
source "./../.env"
set +a

kubectl config set-context --current --namespace="$CONJUR_NAMESPACE"

TOKEN_SECRET_NAME="$(kubectl get secrets | grep 'authn-k8s-sa.*service-account-token' | head -n1 | awk '{print $1}')"
SA_TOKEN="$(kubectl get secret "$TOKEN_SECRET_NAME" --output='go-template={{ .data.token }}' | base64 -d)"
K8S_API_URL="$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')"
K8S_CA_CERT="$(kubectl get secret "$TOKEN_SECRET_NAME" -o json --output='jsonpath={.data.ca\.crt}'  | base64 --decode)"


conjur variable set -i conjur/authn-k8s/"$CONJUR_AUTHENTICATOR_ID"/kubernetes/api-url -v "$K8S_API_URL"
conjur variable set -i conjur/authn-k8s/"$CONJUR_AUTHENTICATOR_ID"/kubernetes/service-account-token -v "$SA_TOKEN"
conjur variable set -i conjur/authn-k8s/"$CONJUR_AUTHENTICATOR_ID"/kubernetes/ca-cert -v "$K8S_CA_CERT"

# Check the Service account access to K8s API
CERT="$(conjur variable get -i conjur/authn-k8s/dev-cluster/kubernetes/ca-cert)"
TOKEN="$(conjur variable get -i conjur/authn-k8s/dev-cluster/kubernetes/service-account-token)"
API="$(conjur variable get -i  conjur/authn-k8s/dev-cluster/kubernetes/api-url)"

echo "$CERT" > k8s.crt
if [[ "$(curl -s --cacert k8s.crt --header "Authorization: Bearer ${TOKEN}" "$API"/healthz)" == "ok" ]]; then
  echo "Service account access to K8s API verified."
else
  echo
  echo ">>> Service account access to K8s API NOT verified. <<<"
  echo
fi
rm k8s.crt
