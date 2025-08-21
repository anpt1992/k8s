#!/bin/bash
set -e
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')

# kubectl config use-context "$KUBE_DEFAULT_CONTEXT"

# KUBE_DEFAULT_CONTEXT="kubernetes-admin@kubernetes"
# kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"
# KUBE_CONTEXT="${KUBE_CONTEXT:-${1:-$KUBE_DEFAULT_CONTEXT}}"

# if ! kubectl get serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE" >/dev/null 2>&1; then
#   kubectl create serviceaccount "$SERVICE_ACCOUNT" -n "$NAMESPACE"
# fi

# TOKEN=$(kubectl create token $SERVICE_ACCOUNT -n $NAMESPACE)
# kubectl config set-credentials anpt-user --token="$TOKEN"
# kubectl config set-context anpt-context --cluster="$CLUSTER_NAME" --namespace="$NAMESPACE" --user=anpt-user
# kubectl config use-context anpt-context