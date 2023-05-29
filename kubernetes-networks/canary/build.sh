#! /bin/bash
until docker info; do sleep 1; done
docker build --tag voitenkov/k8s-intro-web:0.0.2 --tag voitenkov/k8s-intro-web:canary .
docker login -u voitenkov -p $REGISTRY_PASSWORD
docker push voitenkov/k8s-intro-web:0.0.2
docker push voitenkov/k8s-intro-web:canary