#!/bin/bash

set -a
source "./../.env"
source "$CONJUR_K8S_INFO"

set +a

conjur variable set -i conjur/authn-k8s/$CONJUR_AUTHENTICATOR_ID/kubernetes/api-url -v "$K8S_API_URL"
conjur variable set -i conjur/authn-k8s/$CONJUR_AUTHENTICATOR_ID/kubernetes/service-account-token -v "$SA_TOKEN"
conjur variable set -i conjur/authn-k8s/$CONJUR_AUTHENTICATOR_ID/kubernetes/ca-cert -v "$K8S_CA_CERT"