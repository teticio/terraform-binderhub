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
sudo systemctl enable kubelet.service

# install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
sudo helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
sudo helm repo update

# install binderhub
export JUPYTERHUB_API_TOKEN=$(openssl rand -hex 32)
export JUPYTERHUB_SECRET_TOKEN=$(openssl rand -hex 32)
export JUPYTERHUB_COOKIE_SECRET=$(openssl rand -hex 32)
envsubst < /tmp/secret.yaml > /tmp/secret.yaml.tmp
mv /tmp/secret.yaml.tmp /tmp/secret.yaml
envsubst < /tmp/config.yaml > /tmp/config.yaml.tmp
mv /tmp/config.yaml.tmp /tmp/config.yaml
sudo minikube kubectl create namespace binderhub

# install dev version ##########################################
#git clone https://github.com/teticio/binderhub.git
#cd binderhub
#
# build Docker images
#sudo docker build . -f helm-chart/images/binderhub/Dockerfile -t jupyterhub/k8s-binderhub:local
#sudo docker build helm-chart/images/image-cleaner -t jupyterhub/k8s-image-cleaner:local
#
# add Jupyterhub to chart
#mkdir -p helm-chart/binderhub/charts
#cd helm-chart/binderhub/charts
#helm pull jupyterhub/jupyterhub --version=0.11.1
#tar -xvzf jupyterhub-*
#cd ../../../
#
#sudo helm install binderhub helm-chart/binderhub/ --namespace=binderhub -f /tmp/secret.yaml -f /tmp/config.yaml
################################################################

# install prod version
sudo helm install binderhub jupyterhub/binderhub --version=$BINDERHUB_HELM_VERSION --namespace=binderhub -f /tmp/secret.yaml -f /tmp/config.yaml
################################################################

# get binderhub port
export BINDERHUB_PORT=$(sudo kubectl --namespace binderhub get svc binder -o jsonpath='{.spec.ports[0].nodePort}')

# install nginx reverse proxy to serve binderhub on port 80
sudo apt-get install nginx -y
sudo unlink /etc/nginx/sites-enabled/default
envsubst < /tmp/reverse-proxy.conf | sudo tee /etc/nginx/sites-available/reverse-proxy.conf
sudo ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf
sudo service nginx restart

echo "Binderhub running at http://$EC2_PUBLIC_IP"
echo "Test with http://$EC2_PUBLIC_IP/v2/gh/binder-examples/bokeh.git/HEAD?urlpath=%2Fproxy%2F5006%2Fbokeh-app"
echo "You may need to wait for a few minutes for the service to come online"

#ssh ubuntu@$(terraform output -json | jq '.instance_public_ip.value' | tr -d '"')