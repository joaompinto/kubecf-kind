# kubecf-in-kind

Install https://github.com/SUSE/kubecf in https://github.com/kubernetes-sigs/kind


## Requirements
- kind version 0.7.0+
- helm version 3.0.3+

## How to use

```sh
./deploy.sh
```

## ToDo: Expose the API

```bash
# For Linux we can directly expose the node_ip
kubectl expose service kubecf-router-public -n kubecf --name=kubecf-router-public-external --type=LoadBalancer --external-ip=172.17.0.2
```