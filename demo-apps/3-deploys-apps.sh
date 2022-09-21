#!/bin/bash

set -a
source "./../.env"
set +a

#Application owner - Set up the application deployment manifest

cd use-cases/k8s-mongodb-secrets/ && \
    source ./deploy-db.sh && \
    source ./deploy-app-basic.sh && \
    source ./deploy-app-summon.sh && \
    source ./deploy-app-push-to-file.sh && \
    source ./deploy-app-push-to-file-refresh.sh
