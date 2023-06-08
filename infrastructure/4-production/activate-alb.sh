#!/bin/bash

yc iam key create --service-account-name sa-momo-store-prod-k8s-alb --folder-name prod-folder --output ./.secrets/key-sa-alb.json

export HELM_EXPERIMENTAL_OCI=1
cat ./secrets/key-sa-alb.json | helm registry login cr.yandex --username 'json_key' --password-stdin
cd ../charts
helm pull oci://cr.yandex/yc-marketplace/yc-alb-ingress-controller-chart --version=v0.1.3 --untar

export FOLDER_ID=$(yc config get folder-id)
export CLUSTER_ID=$(yc managed-kubernetes cluster get k8s-momo-store-prod-cluster-1 | head -n 1 | awk -F ': ' '{print $2}')
helm install --create-namespace --namespace yc-alb-ingress --set folderId=$FOLDER_ID --set clusterId=$CLUSTER_ID --set-file saKeySecretKey=../4-production/.secrets/key-sa-alb.json yc-alb-ingress-controller yc-alb-ingress-controller-chart/

