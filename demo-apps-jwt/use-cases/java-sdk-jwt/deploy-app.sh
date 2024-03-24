#!/bin/bash

set -a
source "./../../../.env"
set +a

$KUBE_CLI config set-context --current --namespace="$APP_NAMESPACE"

$KUBE_CLI delete secret java-sdk-credentials-jwt --ignore-not-found=true

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

kubectl create configmap conjur-connect-spring-jwt \
  --from-literal SPRING_PROFILES_ACTIVE=secured-java \
  --from-literal CONJUR_ACCOUNT="$CYBERARK_CONJUR_ACCOUNT" \
  --from-literal CONJUR_APPLIANCE_URL="$CONJUR_APPLIANCE_URL" \
  --from-literal CONJUR_AUTHENTICATOR_ID="$CYBERARK_CONJUR_AUTHENTICATOR_ID"  \
  --from-literal CONJUR_JWT_TOKEN_PATH="/var/run/secrets/kubernetes.io/serviceaccount/token" \
  --from-literal LOGGING_LEVEL_COM_CYBERARK=DEBUG  \
  --from-literal SPRING_MAIN_CLOUD_PLATFORM="NONE" \
  --from-file "CONJUR_SSL_CERTIFICATE=conjur.pem" 
  
# DEPLOYMENT
envsubst < deployment.yml | $KUBE_CLI replace --force -f -
if ! $KUBE_CLI wait deployment "$APP_JAVA_SDK_JWT" --for condition=Available=True --timeout=90s
  then exit 1
fi

$KUBE_CLI get services "$APP_JAVA_SDK_JWT"
$KUBE_CLI get pods

rm "$CYBERARK_CONJUR_SSL_CERTIFICATE"
