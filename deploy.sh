#!/bin/sh
kind delete cluster --name kubecf
kind create cluster --name kubecf

kind get kubeconfig --name kubecf > .kubeconfig
KUBECOCONFIG=.kubeconfig

OPERATOR_VERSION=v2.0.0-0.g0142d1e9
KUBECF_VERSION=0.2.0-b8a2dae

kubectl create ns cf-operator
helm install cf-operator \
    --namespace cf-operator \
    --set "global.operator.watchNamespace=kubecf" \
        https://s3.amazonaws.com/cf-operators/helm-charts/cf-operator-${OPERATOR_VERSION}.tgz
echo ""
running_pods=0
while [[ "$running_pods" != "2" ]];
do
  echo "Waiting 20s for the two cf-operator pods to be running..."
  sleep 20
  running_pods=$(kubectl get pods -n cf-operator | grep -c Running)
  echo "Running pods=$running_pods"
done

node_ip=$(kubectl get node kubecf-control-plane \
  --output jsonpath='{ .status.addresses[?(@.type == "InternalIP")].address }')
cat << _EOF_  > values.yaml
system_domain: ${node_ip}.nip.io
features:
  eirini:
    enabled: true
  ingress:
    enabled: false
services:
  router:
    loadBalancerIP: ${node_ip}.nip.io
  ssh-proxy:
    loadBalancerIP: ${node_ip}.nip.io
  tcp-router:
    loadBalancerIP: ${node_ip}.nip.io
kube:
  service_cluster_ip_range: 0.0.0.0/0
  pod_cluster_ip_range: 0.0.0.0/0
_EOF_

helm install kubecf \
    --namespace kubecf \
    --values values.yaml \
    https://scf-v3.s3.amazonaws.com/kubecf-${KUBECF_VERSION}.tgz

watch -t 'echo You will need to wait several minutes until the 19 kubecf pods become ready!;\
  kubectl get pods -n kubecf'


# TODO: expose the
# kubectl expose service kubecf-router-public -n kubecf --name=kubecf-router-public-external --type=LoadBalancer --external-ip=172.17.0.2
#cf api --skip-ssl-validation https://172.17.0.2

# Copy the admin cluster password.
admin_pass=$(kubectl get secret \
        --namespace kubecf kubecf.var-cf-admin-password \
        -o jsonpath='{.data.password}' \
        | base64 --decode)