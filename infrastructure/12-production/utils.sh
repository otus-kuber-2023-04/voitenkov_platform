#!/bin/bash

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg # Add Docker’s official GPG key
# curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg # Download the Google Cloud public signing key:
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null # set up the stable repository
#echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list # Add the Kubernetes apt repository
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gp] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list # Add the Kubernetes apt repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update -y # Update apt package index
apt-get install -y docker-ce docker-ce-cli containerd.io kubectl helm
echo 'export HELM_EXPERIMENTAL_OCI=1' >> ~/.bashrc
mkdir /home/${username}/momo-store
chown ${username}:${username} /home/${username}/momo-store
sudo --user=${username} ssh-keyscan -H gitlab.praktikum-services.ru >> /home/${username}/.ssh/known_hosts
chown ${username}:${username} /home/${username}/.ssh/known_hosts
helm plugin install https://github.com/jkroepke/helm-secrets --version v3.12.0
curl -fsSLo go1.20.2.linux-amd64.tar.gz https://go.dev/dl/go1.20.2.linux-amd64.tar.gz
sudo --user=${username} rm -rf /usr/local/go && sudo --user=${username} tar -C /usr/local -xzf go1.20.2.linux-amd64.tar.gz
echo 'export PATH=/usr/local/go/bin:${PATH}' >> ~/.bashrc
echo 'export GOPATH=~/go' >> ~/.bashrc
echo 'export PATH=${GOPATH}/bin:${PATH}' >> ~/.bashrc
echo 'export GOPROXY=https://proxy.golang.org' >> ~/.bashrc
source ~/.bashrc
mkdir $GOPATH
go install go.mozilla.org/sops/v3/cmd/sops@latest
go install filippo.io/age/cmd/...@latest
curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash -s -- -a
