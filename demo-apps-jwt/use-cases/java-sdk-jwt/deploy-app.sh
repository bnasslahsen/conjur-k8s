#!/bin/bash

set -a
source "./../../../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

kubectl delete configmap conjur-connect-spring-jwt --ignore-not-found=true

openssl s_client -connect "$CYBERARK_CONJUR_MASTER_HOSTNAME":"$CYBERARK_CONJUR_MASTER_PORT" \
  -showcerts </dev/null 2> /dev/null | \
  awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/ {print $0}' \
  > "$CYBERARK_CONJUR_SSL_CERTIFICATE"

FOLLOWER_URL="https://$FOLLOWER_SERVICE_NAME.$CYBERARK_CONJUR_NAMESPACE.svc.cluster.local"
if "$USE_K8S_FOLLOWER" ; then
  APPLIANCE_URL=$FOLLOWER_URL
else
  APPLIANCE_URL=$CYBERARK_CONJUR_APPLIANCE_URL
fi


kubectl delete configmap mapping-config-jwt --ignore-not-found=true
kubectl create configmap mapping-config-jwt --from-file=conjur.properties

kubectl create configmap conjur-connect-spring-jwt \
  --from-literal SPRING_PROFILES_ACTIVE=secured \
  --from-literal CONJUR_ACCOUNT="$CYBERARK_CONJUR_ACCOUNT" \
  --from-literal CONJUR_APPLIANCE_URL="$APPLIANCE_URL" \
  --from-literal CONJUR_AUTHENTICATOR_ID="$CYBERARK_CONJUR_AUTHENTICATOR_ID"  \
  --from-literal CONJUR_JWT_TOKEN_PATH="/var/run/secrets/kubernetes.io/serviceaccount/token" \
  --from-literal CONJUR_MAPPING_PATH="/opt/secrets/conjur/conjur.properties" \
  --from-literal LOGGING_LEVEL_COM_CYBERARK=DEBUG  \
  --from-literal SPRING_MAIN_CLOUD_PLATFORM="NONE" \
  --from-file "CONJUR_SSL_CERTIFICATE=conjur.pem" 
  
# DEPLOYMENT
envsubst < deployment.yml | kubectl replace --force -f -
if ! kubectl wait deployment $APP_NAME-jwt --for condition=Available=True --timeout=90s
  then exit 1
fi

kubectl get services $APP_NAME-jwt
kubectl get pods

rm "$CYBERARK_CONJUR_SSL_CERTIFICATE"
