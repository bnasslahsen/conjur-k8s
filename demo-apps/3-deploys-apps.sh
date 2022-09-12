#!/bin/bash

set -a
source "./../.env"
set +a

#Application owner - Set up the application deployment manifest
cd use-cases/basic-k8s-secrets && source ./deploy-app.sh
cd ../secrets-provider-for-k8s-init && source ./deploy-app.sh
cd ../secrets-provider-for-k8s-sidecar && source ./deploy-app.sh
cd ../summon-init && source ./deploy-app.sh
cd ../summon-sidecar && source ./deploy-app.sh
cd ../secretless-postgres && source  ./deploy-app.sh
cd ../secretless-mysql && source  ./deploy-app.sh
cd ../springboot && source ./deploy-app.sh