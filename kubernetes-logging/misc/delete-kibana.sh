#!/bin/bash

kubectl delete role pre-install-kibana-kibana -n observability
kubectl delete cm kibana-kibana-helm-scripts -n observability
kubectl delete sa pre-install-kibana-kibana -n observability
kubectl delete rolebinding pre-install-kibana-kibana -n observability
kubectl delete jobs.batch pre-install-kibana-kibana -n observability
kubectl delete cm kibana-kibana-helm-scripts -n observability
