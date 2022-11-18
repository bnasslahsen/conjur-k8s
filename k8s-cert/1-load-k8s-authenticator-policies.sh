#!/bin/bash

set -a
source "./../.env"
set +a

#Set up a Kubernetes Authenticator endpoint in Conjur
envsubst < policies/k8s-authenticator-webservice.yml > k8s-authenticator-webservice.yml.tmp
conjur policy update -b root -f k8s-authenticator-webservice.yml.tmp

#Enable the seed generation service
if "$USE_K8S_FOLLOWER";
  then conjur policy update -f policies/seed-generation.yml -b root
fi

openssl genrsa -out ca.key 2048

### CA CONFIG ###
CONFIG="
[ req ]
distinguished_name = dn
x509_extensions = v3_ca
[ dn ]
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always
"

openssl req -x509 -new -nodes -key ca.key -sha1 -days 3650 -set_serial 0x0 -out ca.cert \
  -subj "/CN=conjur.authn-k8s.$CONJUR_AUTHENTICATOR_ID/OU=Conjur Kubernetes CA/O=$CONJUR_ACCOUNT" \
  -config <(echo "$CONFIG")

openssl x509 -in ca.cert -text -noout

conjur variable set -i conjur/authn-k8s/"$CONJUR_AUTHENTICATOR_ID"/ca/key -v "$(cat ca.key)"

conjur variable set -i conjur/authn-k8s/"$CONJUR_AUTHENTICATOR_ID"/ca/cert -v "$(cat ca.cert)"

rm ca.key ca.cert k8s-authenticator-webservice.yml.tmp

read -p "Press enter when k8s Authenticator in enabled in conjur..."

#podman exec dap evoke variable set CONJUR_AUTHENTICATORS authn,authn-k8s/"$CONJUR_AUTHENTICATOR_ID"

#Verify that the Kubernetes Authenticator is configured and allowlisted
RESULT=$(curl -sSk https://"$CONJUR_MASTER_HOSTNAME":"$CONJUR_MASTER_PORT"/info  | grep "$CONJUR_AUTHENTICATOR_ID" | wc -w)

if [[ $RESULT -ne 2 ]]; then
  echo "Kubernetes Authenticator not enabled!"
  exit 1
else
  echo "Kubernetes Authenticator $CONJUR_AUTHENTICATOR_ID enabled!"
fi