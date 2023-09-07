#! /bin/bash
until docker info; do sleep 1; done
docker build --tag voitenkov/k8s-mysql-operator:0.0.8 --tag voitenkov/k8s-mysql-operator:latest .
docker login -u voitenkov -p $REGISTRY_PASSWORD
docker push voitenkov/k8s-mysql-operator:0.0.8
docker push voitenkov/k8s-mysql-operator:latest
