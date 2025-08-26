#!/bin/bash
set -e

# Set environment (dev/prod) from first argument, default to dev
ENV="${1:-dev}"

NAMESPACE=final-assigment

kubectl get namespace "$NAMESPACE" >/dev/null 2>&1 || kubectl create namespace "$NAMESPACE"

kubectl config set-context --current --namespace "$NAMESPACE"

# Apply all manifests using Kustomize overlay

# Helper: detect if a CNI is already installed (calico/cilium/flannel/weave/canal)
detect_cni() {
  # return 0 if any known CNI daemonset or pod is present
  if kubectl get daemonsets -n kube-system -o name 2>/dev/null | grep -E 'calico|cilium|flannel|weave|canal|kube-flannel' >/dev/null 2>&1; then
    return 0
  fi
  if kubectl get pods -n kube-system -o name 2>/dev/null | grep -E 'calico|cilium|flannel|weave|canal|kube-flannel' >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# --- PROD-ONLY SETUP ---
if [[ "$ENV" == "prod" ]]; then
  echo "[INFO] Running prod-only setup: Ingress controller, MetalLB, StorageClass, etc."
  # Install MetalLB if not present
  if ! kubectl get ns metallb-system >/dev/null 2>&1; then
    echo "[INFO] Installing MetalLB..."
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
  fi

  # Install nginx ingress controller if not present
  if ! kubectl get ns ingress-nginx >/dev/null 2>&1; then
    echo "[INFO] Installing nginx ingress controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml
  fi

  # Install metrics-server if not present
  if ! kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
    echo "[INFO] Installing metrics-server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
  else
    echo "[INFO] metrics-server already installed"
  fi

  # Install Calico CNI if no other CNI is detected
  if ! detect_cni; then
    echo "[INFO] No CNI detected. Installing Calico CNI..."
    kubectl apply -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
    kubectl apply -f https://docs.projectcalico.org/manifests/custom-resources.yaml
  else
    echo "[INFO] CNI detected in cluster; skipping Calico installation."
  fi

  # Install StorageClass if not present (example for local-path)
  if ! kubectl get storageclass local-path >/dev/null 2>&1; then
    echo "[INFO] Installing local-path StorageClass..."
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.26/deploy/local-path-storage.yaml
  fi
  
  # Ensure the TLS secret is created from the latest cert files before applying manifests in prod, but only if cert folder and files exist

  if [[ -d cert && -f cert/origin.crt && -f cert/origin.key ]]; then
    kubectl create secret tls cloudflare-origin-cert --cert=cert/origin.crt --key=cert/origin.key -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
  else
    echo "[INFO] Skipping TLS secret creation: cert/origin.crt or cert/origin.key not found."
  fi

  # --- Monitoring stack: Prometheus, Grafana, Node Exporter, Kube API, PG Exporter ---
  echo "[INFO] Setting up monitoring stack (Prometheus, Grafana, exporters) via Helm..."
  if ! command -v helm >/dev/null 2>&1; then
    echo "[ERROR] Helm is not installed. Please install Helm and re-run the script."
    exit 1
  fi
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || true
  helm repo add grafana https://grafana.github.io/helm-charts || true
  helm repo update
  # Install or upgrade kube-prometheus-stack (includes Prometheus, Grafana, Node Exporter, Kube API monitoring)
  helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring --create-namespace \
    --set grafana.ingress.enabled=false \
    --set prometheus.ingress.enabled=false
  # Optionally install PG Exporter (if you want a separate deployment)
  # helm upgrade --install prometheus-postgres-exporter prometheus-community/prometheus-postgres-exporter --namespace monitoring --create-namespace
  echo "[INFO] Waiting for Grafana pod to be ready..."
  kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=180s || true
  echo "[INFO] Grafana admin password:"
  kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode; echo

  # Ensure the monitoring namespace TLS secret is always up-to-date after Helm install
  if [[ -d cert && -f cert/origin.crt && -f cert/origin.key ]]; then
    kubectl create secret tls cloudflare-origin-cert --cert=cert/origin.crt --key=cert/origin.key -n monitoring --dry-run=client -o yaml | kubectl apply -f -
  fi
    echo "[INFO] Skipping TLS secret creation: cert/origin.crt or cert/origin.key not found."
  fi
fi

if [[ "$ENV" == "dev" ]]; then
  # only on a machine running minikube
  if minikube status >/dev/null 2>&1; then
    echo "[INFO] Detected minikube, enabling addons (ingress, storage-provisioner)"
    minikube addons enable ingress
    minikube addons enable metrics-server
    minikube addons enable storage-provisioner
    # optionally map host (ask user for sudo)
    MINIKUBE_IP=$(minikube ip)
    echo "[INFO] Add to /etc/hosts: $MINIKUBE_IP product-inventory.local"
  fi
fi


# Apply the correct overlay for the environment
if [[ "$ENV" == "prod" ]]; then
  kubectl apply -k overlays/prod
else
  kubectl apply -k overlays/dev
fi

kubectl get all