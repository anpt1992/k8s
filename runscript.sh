#!/bin/bash
set -e

NAMESPACE=final-assigment

kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

kubectl config set-context --current --namespace "$NAMESPACE"
kubectl apply -f postgres/pv.yaml
kubectl apply -f postgres/pvc.yaml
kubectl apply -f postgres/deployment.yaml
kubectl apply -f postgres/service.yaml
kubectl apply -f postgres/secret.yaml

kubectl apply -f product-inventory-api/deployment.yaml
kubectl apply -f product-inventory-api/service.yaml
kubectl apply -f product-inventory-api/ingress.yaml

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl get all