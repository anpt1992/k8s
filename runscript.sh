#!/bin/bash
set -e

NAMESPACE=final-assigment

kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

kubectl config set-context --current --namespace "$NAMESPACE"

# Apply all manifests using Kustomize overlay

echo "[INFO] Running setup..."
# Install MetalLB
if ! kubectl get ns metallb-system >/dev/null 2>&1; then
  echo "[INFO] Installing MetalLB..."
  kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
fi

# Install Gateway API CRDs
echo "[INFO] Installing Gateway API CRDs..."
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml || true

# Install Envoy Gateway
if ! kubectl get ns envoy-gateway-system >/dev/null 2>&1; then
  echo "[INFO] Installing Envoy Gateway..."
  helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.2.0 -n envoy-gateway-system --create-namespace --skip-crds
  echo "[INFO] Waiting for Envoy Gateway to be ready..."
  kubectl wait --for=condition=Available deployment/envoy-gateway -n envoy-gateway-system --timeout=300s
fi

# Install StorageClass
if ! kubectl get storageclass local-path >/dev/null 2>&1; then
  echo "[INFO] Installing local-path StorageClass..."
  kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml
fi

# Create TLS secret if certs exist
if [[ -d cert && -f cert/origin.crt && -f cert/origin.key ]]; then
  # Create secret in application namespace
  kubectl create secret tls cloudflare-origin-cert --cert=cert/origin.crt --key=cert/origin.key -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
  # Create secret in envoy-gateway-system namespace (for Gateway)
  kubectl create secret tls cloudflare-origin-cert --cert=cert/origin.crt --key=cert/origin.key -n envoy-gateway-system --dry-run=client -o yaml | kubectl apply -f -
else
  echo "[INFO] Skipping TLS secret creation: cert/origin.crt or cert/origin.key not found."
fi

# Apply Gateway resource
kubectl apply -f base/gateway.yaml



# --- Monitoring stack ---
echo "[INFO] Setting up monitoring..."
if ! command -v helm >/dev/null 2>&1; then
  echo "[ERROR] Helm is not installed. Please install Helm and re-run the script."
  exit 1
fi
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update >/dev/null
# Install kube-prometheus-stack
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --version 69.7.1 \
  --namespace monitoring --create-namespace \
  --set grafana.ingress.enabled=false \
  --set prometheus.ingress.enabled=false \
  -f monitoring/grafana-smtp-values.yaml
# Install PG Exporter
helm upgrade --install prometheus-postgres-exporter prometheus-community/prometheus-postgres-exporter --version 7.3.0 --namespace monitoring --create-namespace
echo "[INFO] Waiting for Grafana pod to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=180s || true
# Install MailHog
kubectl apply -f monitoring/mailhog.yaml -n monitoring
kubectl apply -f monitoring/httproute-monitoring.yaml -n monitoring
echo "[INFO] MailHog deployed in namespace 'monitoring'"
echo "[INFO] Grafana admin password:"
kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode; echo

# Create monitoring TLS secret
if [[ -d cert && -f cert/origin.crt && -f cert/origin.key ]]; then
  kubectl create secret tls cloudflare-origin-cert --cert=cert/origin.crt --key=cert/origin.key -n monitoring --dry-run=client -o yaml | kubectl apply -f -
else
  echo "[INFO] Skipping TLS secret creation: cert/origin.crt or cert/origin.key not found."
fi


# Apply the correct overlay for the environment
kubectl apply -k overlays/prod

kubectl get all