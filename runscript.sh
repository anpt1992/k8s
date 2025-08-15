#!/bin/bash
set -e

NAMESPACE=final-assigment

kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

kubectl config set-context --current --namespace "$NAMESPACE"
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl get pods
kubectl port-forward service/crudapp 8080:8080