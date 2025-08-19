#!/bin/bash
set -e

NAMESPACE=final-assigment
SERVICE_ACCOUNT=devops-sa
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')

kubectl config use-context minikube

kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

kubectl create serviceaccount $SERVICE_ACCOUNT -n $NAMESPACE

kubectl apply -f rbac-anpt-sa.yaml

TOKEN=$(kubectl create token $SERVICE_ACCOUNT -n $NAMESPACE)

# Create new user credentials with the token
kubectl config set-credentials anpt-user --token="$TOKEN"

# Create a new context for the user
kubectl config set-context anpt-context --cluster="$CLUSTER_NAME" --namespace="$NAMESPACE" --user=anpt-user

kubectl config use-context anpt-context

kubectl config set-context --current --namespace "$NAMESPACE"

# Apply Kubernetes manifests

kubectl apply -f postgres/

kubectl apply -f product-inventory-api/

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl get all