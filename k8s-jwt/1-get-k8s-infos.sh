#!/bin/bash

set -a
source "./../.env"
set +a

JWKS_URI=$($KUBE_CLI get --raw /.well-known/openid-configuration | jq -r '.jwks_uri')
echo "JWKS_URI=\"$JWKS_URI\"" > "$CONJUR_K8S_INFO"

$KUBE_CLI get --raw $($KUBE_CLI get --raw /.well-known/openid-configuration | jq -r '.jwks_uri') > jwks.json

SA_ISSUER="$($KUBE_CLI get --raw /.well-known/openid-configuration | jq -r '.issuer')"
echo "SA_ISSUER=\"$SA_ISSUER\"" >> "$CONJUR_K8S_INFO"
