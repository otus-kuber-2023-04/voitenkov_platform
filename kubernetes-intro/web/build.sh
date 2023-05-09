#! /bin/bash
until docker info; do sleep 1; done
docker build --tag voitenkov/k8s-intro-web:0.0.1 .
docker login -u voitenkov -p $REGISTRY_PASSWORD
docker push voitenkov/k8s-intro-web:0.0.1
