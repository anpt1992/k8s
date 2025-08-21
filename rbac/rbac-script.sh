#!/usr/bin/env bash
set -euo pipefail

# Simple RBAC helper
# Usage: ./rbac-script.sh [NAMESPACE]
# Example: ./rbac-script.sh final-assigment

NAMESPACE="${1:-final-assigment}"
SA="anpt-sa"
RBAC_FILE="$(dirname "$0")/rbac-anpt-sa.yaml"
echo "[INFO] switching to default admin context if present: kubernetes-admin@kubernetes"
kubectl config get-contexts "kubernetes-admin@kubernetes" >/dev/null 2>&1 && kubectl config use-context "kubernetes-admin@kubernetes"

echo "[INFO] ensuring namespace $NAMESPACE"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "[INFO] ensuring serviceaccount $SA in $NAMESPACE"
kubectl create sa "$SA" -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f rbac/rbac-anpt-sa.yaml

echo "[INFO] creating token for $SA"
TOKEN=$(kubectl create token "$SA" -n "$NAMESPACE")

CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
kubectl config set-credentials anpt-user --token="$TOKEN"
kubectl config set-context anpt-context --cluster="$CLUSTER_NAME" --namespace="$NAMESPACE" --user=anpt-user
kubectl config use-context anpt-context

echo "[DONE] RBAC applied and context 'anpt-context' configured for namespace $NAMESPACE"