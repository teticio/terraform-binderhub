#!/usr/bin/env bash
set -eo pipefail
sudo apt-get update

# needed for minikube
sudo apt-get install conntrack -y

# install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

# install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# install minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
sudo minikube start --driver=none

# install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
sudo helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
sudo helm repo update

# install binderhub
export JUPYTERHUB_API_TOKEN=$(openssl rand -hex 32)
export JUPYTERHUB_SECRET_TOKEN=$(openssl rand -hex 32)
envsubst < /tmp/secret.yaml > /tmp/secret.yaml.tmp
mv /tmp/secret.yaml.tmp /tmp/secret.yaml
envsubst < /tmp/config.yaml > /tmp/config.yaml.tmp
mv /tmp/config.yaml.tmp /tmp/config.yaml
sudo minikube kubectl create namespace binderhub
sudo helm install binderhub jupyterhub/binderhub --version=$BINDERHUB_HELM_VERSION --namespace=binderhub -f /tmp/secret.yaml -f /tmp/config.yaml

# get jupyterhub port and point binderhub to it
sudo kubectl --namespace binderhub get svc proxy-public -o jsonpath='{.spec.ports[0].nodePort}' > jupyterhub_port
sed -i "s/<URL>/http:\/\/$EC2_PUBLIC_IP:$(cat jupyterhub_port)/" /tmp/config.yaml

# upgrade binderhub with new config and get port
sudo helm upgrade binderhub jupyterhub/binderhub --version=$BINDERHUB_HELM_VERSION --namespace=binderhub -f /tmp/secret.yaml -f /tmp/config.yaml
sudo kubectl --namespace binderhub get svc binder -o jsonpath='{.spec.ports[0].nodePort}' > binderhub_port
export BINDERHUB_URL=http://$EC2_PUBLIC_IP:$(cat binderhub_port)

echo "Binderhub running at $BINDERHUB_URL"
echo "Test with $BINDERHUB_URL/v2/gh/binder-examples/bokeh.git/HEAD?urlpath=%2Fproxy%2F5006%2Fbokeh-app"
echo "You may need to wait for a few minutes for the service to come online"
