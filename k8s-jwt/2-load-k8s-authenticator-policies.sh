#!/bin/bash

set -a
source "./../.env"
set +a

#Set up a Kubernetes Authenticator endpoint in Conjur
envsubst < policies/jwt-authenticator-webservice.yaml > jwt-authenticator-webservice.yaml.tmp
conjur policy update -f jwt-authenticator-webservice.yaml.tmp -b root

rm jwt-authenticator-webservice.yaml.tmp

#Enable the seed generation service
if "$USE_K8S_FOLLOWER";
  then conjur policy update -f policies/seed-generation.yml -b root
fi