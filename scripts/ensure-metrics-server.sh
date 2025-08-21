#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-kube-system}
DEPLOY=${DEPLOY:-metrics-server}

if ! kubectl get deployment "$DEPLOY" -n "$NAMESPACE" >/dev/null 2>&1; then
	echo "[metrics] deployment '$DEPLOY' not found in namespace '$NAMESPACE' — skipping (install first)"
	exit 0
fi

echo "[metrics] patching $DEPLOY args and securityContext"
kubectl -n "$NAMESPACE" patch deployment "$DEPLOY" --type='strategic' -p '{"spec":{"template":{"spec":{"containers":[{"name":"metrics-server","args":["--kubelet-insecure-tls","--kubelet-preferred-address-types=InternalIP,Hostname,ExternalIP","--cert-dir=/tmp","--secure-port=4443"],"securityContext":{"capabilities":{"add":["NET_BIND_SERVICE"],"drop":["ALL"]},"allowPrivilegeEscalation":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"runAsUser":1000}}]}}}}' || true

echo "[metrics] restarting deployment"
kubectl -n "$NAMESPACE" rollout restart deployment "$DEPLOY" || true
kubectl -n "$NAMESPACE" rollout status deployment "$DEPLOY" --timeout=120s || true

echo "[metrics] done"

