# Flux CD Repository for Kubernetes Cluster

This repository contains the GitOps configurations for managing a Kubernetes cluster with FluxCD. It follows the [Flux GitOps Toolkit](https://fluxcd.io/docs/components/) structure.

## Structure

```
clusters/
└── default/              # Cluster name
    ├── infrastructure/   # Core infrastructure components
    │   └── cilium/       # Cilium CNI configuration
    └── kustomization.yaml
```

## Components

### Cilium

The Cilium CNI configuration is based on the settings from the `terraform-proxmox-talos-k8s` project. It includes:

- Version: 1.15.6
- Configured for Talos Linux with kube-proxy replacement enabled
- Appropriate security context and capabilities

## Usage

This repository is meant to be used with Flux CD to automatically deploy and synchronize resources to your Kubernetes cluster. 

To bootstrap Flux on your cluster, follow the [Flux bootstrap guide](https://fluxcd.io/docs/installation/).
