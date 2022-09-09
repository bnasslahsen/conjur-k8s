#!/bin/bash

set -a
source "./../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$CONJUR_NAMESPACE"

TOKEN_SECRET_NAME="$($KUBE_CLI get secrets | grep 'authn-k8s-sa.*service-account-token' | head -n1 | awk '{print $1}')"
SA_TOKEN="$($KUBE_CLI get secret "$TOKEN_SECRET_NAME" --output='go-template={{ .data.token }}' | base64 -d)"
K8S_API_URL="$($KUBE_CLI config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')"
K8S_CA_CERT="$($KUBE_CLI get secret "$TOKEN_SECRET_NAME" -o json --output='jsonpath={.data.ca\.crt}'  | base64 --decode)"

conjur variable set -i conjur/authn-k8s/$CONJUR_AUTHENTICATOR_ID/kubernetes/api-url -v "$K8S_API_URL"
conjur variable set -i conjur/authn-k8s/$CONJUR_AUTHENTICATOR_ID/kubernetes/service-account-token -v "$SA_TOKEN"
conjur variable set -i conjur/authn-k8s/$CONJUR_AUTHENTICATOR_ID/kubernetes/ca-cert -v "$K8S_CA_CERT"


TOKEN_SECRET_NAME="$(oc get secrets | grep 'authn-k8s-sa.*service-account-token' | head -n1 | awk '{print $1}')"
SA_TOKEN="$(oc get secret "$TOKEN_SECRET_NAME" --output='go-template={{ .data.token }}' | base64 -d)"
K8S_API_URL="$(oc config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')"
K8S_CA_CERT="$(oc get secret "$TOKEN_SECRET_NAME" -o json --output='jsonpath={.data.ca\.crt}'  | base64 --decode)"