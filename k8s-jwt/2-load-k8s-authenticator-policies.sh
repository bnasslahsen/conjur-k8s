#!/bin/bash

set -a
source "./../.env"
set +a

# Load the applications branch
conjur policy update -b root -f <(envsubst < policies/app-branch.yml)

conjur policy update -b root -f <(envsubst < policies/jwt-authenticator-webservice.yaml)

#Enable the seed generation service
if "$USE_K8S_FOLLOWER";
  then conjur policy update -f policies/seed-generation.yml -b root
fi