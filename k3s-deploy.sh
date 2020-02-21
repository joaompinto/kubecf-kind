# Install k3s with the kubeconfig readable for everyone
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--write-kubeconfig-mode 0644" sh -

# Install Helm 3
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get-helm-3 | sh -

# Make sure we use the kubctl provided by k3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Create the NS for the cf-operator
kubectl create ns cf-operator

version="2.3.0%2B0.g27a91cdf"
helm install cf-operator \
    --namespace cf-operator \
    --set "global.operator.watchNamespace=kubecf" \
    https://s3.amazonaws.com/cf-operators/release/helm-charts/cf-operator-${version}.tgz

cat << _EOF_  > values.yaml
system_domain: 192.168.0.15.nip.io
kube:
    service_cluster_ip_range: 0.0.0.0/0
    pod_cluster_ip_range: 0.0.0.0/0
_EOF_

running_pods=0
while [[ "$running_pods" != "2" ]];
do
    echo "Waiting 20s for the two cf-operator pods to be running..."
    sleep 20
    running_pods=$(kubectl get pods -n cf-operator | grep -c Running)
    echo "Running pods=$running_pods"
done


helm install kubecf \
    --namespace kubecf \
    --values values.yaml \
    https://scf-v3.s3.amazonaws.com/kubecf-v0.0.0-e7534b6.tgz

