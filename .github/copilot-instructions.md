# Copilot Instructions for This Repository

This file provides guidance for using GitHub Copilot effectively with this project.

## Recommended Custom Instructions

When setting up Copilot Custom Instructions in VS Code, consider the following:

**How would you like Copilot to respond?**
- Suggest concise, production-ready Kubernetes YAML, Bash scripts, and .NET code.
- Follow best practices for kustomize overlays and cloud-native infrastructure.
- Prometheus url exposed at https://prometheus.anpt1992.dev/
- Grafana url exposed at https://grafana.anpt1992.dev/
- If get NetworkPluginNotReady message: Network plugin returns error: cni plugin not initialized then suggest sudo systemctl restart containerd

**What would you like Copilot to know about your project?**
- This repository contains Kubernetes manifests, kustomize overlays, Helm charts, monitoring (Prometheus, Grafana), and .NET microservices.
- YAML files are used for Kubernetes resources and configuration.
- Scripts are Bash unless otherwise noted.

## How to Set Custom Instructions
1. Open the Command Palette in VS Code (`Ctrl+Shift+P`).
2. Search for `Copilot: Custom Instructions`.
3. Fill in the prompts using the recommendations above.

For more details, see the [official documentation](https://code.visualstudio.com/docs/copilot/customization/custom-instructions).
