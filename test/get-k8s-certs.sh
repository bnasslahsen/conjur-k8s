#!/bin/bash

K8S_API_HOST=api.emeacluster.emea-devops-lab.cybr
K8S_API_URL="https://$K8S_API_HOST:6443"
CONJUR_CONTAINER="dap-12.7"
CONJUR_AUTHENTICATOR_ID="ocp-cluster"
CONTAINER_MGR=podman
K8S_CA_FILE="k8s-ca.crt"

$CONTAINER_MGR exec $CONJUR_CONTAINER openssl s_client -showcerts -connect ${K8S_API_URL#https://} -servername ${K8S_API_HOST} < /dev/null 2> /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > "$K8S_CA_FILE"
$CONTAINER_MGR exec $CONJUR_CONTAINER openssl s_client -showcerts -connect ${K8S_API_URL#https://} < /dev/null 2> /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' >> "$K8S_CA_FILE"

conjur variable set -i conjur/authn-k8s/$CONJUR_AUTHENTICATOR_ID/kubernetes/ca-cert -v "$(cat $K8S_CA_FILE)"