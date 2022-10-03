#!/bin/bash

CONJUR_AUTHENTICATOR_ID=demo-application

# Check the Service account access to K8s API
CERT="$(conjur variable get -i conjur/authn-k8s/"$CONJUR_AUTHENTICATOR_ID"/kubernetes/ca-cert)"
TOKEN="$(conjur variable get -i conjur/authn-k8s/"$CONJUR_AUTHENTICATOR_ID"/kubernetes/service-account-token)"
API="$(conjur variable get -i  conjur/authn-k8s/"$CONJUR_AUTHENTICATOR_ID"/kubernetes/api-url)"

echo "$CERT" > k8s.crt
if [[ "$(curl -s --cacert k8s.crt --header "Authorization: Bearer ${TOKEN}" "$API"/healthz)" == "ok" ]]; then
  echo "Service account access to K8s API verified."
else
  echo
  echo ">>> Service account access to K8s API NOT verified. <<<"
  echo
fi
rm k8s.crt
