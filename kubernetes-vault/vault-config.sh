#! /bin/bash

export SA_SECRET_NAME=$(kubectl get secrets --output=json    | jq -r '.items[].metadata | select(.name|startswith("vault-auth-")).name')
export SA_JWT_TOKEN=$(kubectl get secret $SA_SECRET_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl config view --raw --minify --flatten   --output 'jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
export K8S_HOST=$(kubectl config view --raw --minify --flatten   --output 'jsonpath={.clusters[].cluster.server}')
vault write auth/kubernetes/config token_reviewer_jwt="$SA_JWT_TOKEN" kubernetes_host="$K8S_HOST" kubernetes_ca_cert="$SA_CA_CRT"