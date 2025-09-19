#!/bin/bash
# init-cluster.sh: Initialize Kubernetes cluster and install Calico CNI v3.28.1
set -e

# 1. Initialize Kubernetes cluster (customize as needed)
echo "[Step 1] Initializing Kubernetes cluster with external IP 154.26.134.15..."
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=154.26.134.15

# 2. Set up kubeconfig for current user
echo "[Step 2] Setting up kubeconfig..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


# 3. Install Calico using tigera-operator and custom resources
echo "[Step 3] Installing Calico CNI v3.28.1 using tigera-operator..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/tigera-operator.yaml
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/custom-resources.yaml
kubectl create -f custom-resources.yaml

# 4. Taint removal for single-node clusters (optional)
echo "[Step 4] Removing master node taint (optional for single-node clusters)..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# 5. Wait for Calico pods to be ready
echo "[Step 5] Waiting for Calico pods to be ready..."
kubectl -n calico-system wait --for=condition=Ready pod --all --timeout=180s

echo "Kubernetes cluster initialized and Calico CNI v3.28.1 installed."
