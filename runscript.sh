#!/bin/bash
set -e

NAMESPACE=final-assigment

kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

kubectl config set-context --current --namespace "$NAMESPACE"
kubectl apply -f product-inventory-api/deployment.yaml
kubectl apply -f product-inventory-api/service.yaml
kubectl apply -f product-inventory-api/ingress.yaml
kubectl get pods