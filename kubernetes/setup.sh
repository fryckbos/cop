#!/bin/bash

source conf.sh
source ../services.sh

# Create the namespace
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
  labels:
    name: $NAMESPACE
EOF

kubectl create secret docker-registry coscale-registry \
    --docker-server="$REGISTRY" \
    --docker-username="$REGISTRY_USERNAME" \
    --docker-password="$REGISTRY_PASSWORD" \
    --docker-email="$API_SUPER_USER" \
    --namespace="$NAMESPACE"

# Create the services
kubectl apply -f services/services.yaml -n $NAMESPACE

# Create the environment variables section
echo "        env:" > env.yaml
for VAR in $(cat ../conf.sh | grep '^export' | grep -v REGISTRY | awk '{ print $2; }' | awk -F= '{ print $1; }'); do
    if [ "${!VAR}" != "" ]; then
        echo "        - name: ${VAR}" >> env.yaml
        echo "          value: \"${!VAR}\"" >> env.yaml
    fi
done

# Deploy the pods
for SERVICE in $DATA_SERVICES $COSCALE_SERVICES $LB_SERVICE; do

eval "cat <<EOF
$(<services/${SERVICE}.yaml)
$(<env.yaml)
EOF" | kubectl apply -n $NAMESPACE -f -

done

rm env.yaml
