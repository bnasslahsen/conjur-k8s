#!/bin/bash

set -a
source "./../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$CONJUR_NAMESPACE"

TOKEN_SECRET_NAME="$($KUBE_CLI get secrets | grep 'authn-k8s-sa.*service-account-token' | head -n1 | awk '{print $1}')"
SA_TOKEN="$($KUBE_CLI get secret "$TOKEN_SECRET_NAME" --output='go-template={{ .data.token }}' | base64 -d)"
echo "SA_TOKEN=\"$SA_TOKEN\"" > "$CONJUR_K8S_INFO"

K8S_API_URL="$($KUBE_CLI config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')"
echo "K8S_API_URL=\"$K8S_API_URL\"" >> "$CONJUR_K8S_INFO"

K8S_CA_CERT="$($KUBE_CLI get secret "$TOKEN_SECRET_NAME" -o json --output='jsonpath={.data.ca\.crt}'  | base64 --decode)"
echo "K8S_CA_CERT=\"$K8S_CA_CERT\"" >> "$CONJUR_K8S_INFO"