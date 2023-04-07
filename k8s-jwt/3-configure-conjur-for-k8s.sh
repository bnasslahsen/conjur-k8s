#!/bin/bash

set -a
source "./../.env"
source "$CYBERARK_CONJUR_K8S_INFO"

set +a

conjur variable set -i conjur/authn-jwt/$CYBERARK_CONJUR_AUTHENTICATOR_ID/public-keys -v "{\"type\":\"jwks\", \"value\":$(cat jwks.json)}"
conjur variable set -i conjur/authn-jwt/$CYBERARK_CONJUR_AUTHENTICATOR_ID/issuer -v $SA_ISSUER
conjur variable set -i conjur/authn-jwt/$CYBERARK_CONJUR_AUTHENTICATOR_ID/token-app-property -v "sub"
conjur variable set -i conjur/authn-jwt/$CYBERARK_CONJUR_AUTHENTICATOR_ID/identity-path -v "$FOLLOWER_BASE_PATH"
conjur variable set -i conjur/authn-jwt/$CYBERARK_CONJUR_AUTHENTICATOR_ID/audience -v "conjur"

read -p "Press enter when k8s Authenticator in enabled in conjur..."

#podman exec dap evoke variable set CYBERARK_CONJUR_AUTHENTICATORS authn,authn-k8s/"$CYBERARK_CONJUR_AUTHENTICATOR_ID"

#Verify that the Kubernetes Authenticator is configured and allowlisted
RESULT=$(curl -sSk https://"$CYBERARK_CONJUR_MASTER_HOSTNAME":"$CYBERARK_CONJUR_MASTER_PORT"/info  | grep "$CYBERARK_CONJUR_AUTHENTICATOR_ID" | wc -w)

if [[ $RESULT -ne 2 ]]; then
  echo "Kubernetes Authenticator not enabled!"
  exit 1
else
  echo "Kubernetes Authenticator $CYBERARK_CONJUR_AUTHENTICATOR_ID enabled!"
fi