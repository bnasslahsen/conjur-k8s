# Set environment. Modify as necessary to match your setup.
APP_NAMESPACE="bnl-test-app-namespace"
APP_POD_LABEL="app=test-app-secretless"
AUTHN_CONTAINER="configurator"

APP_POD_NAME="$(kubectl get pod \
                -n $APP_NAMESPACE \
                -l $APP_POD_LABEL \
                -o jsonpath='{.items[0].metadata.name}')"
kubectl exec \
        -n $APP_NAMESPACE \
        $APP_POD_NAME \
        -c $AUTHN_CONTAINER \
        -- printenv CONJUR_ACCOUNT