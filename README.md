# Flux CD Repository for Kubernetes Cluster

This repository contains the GitOps configurations for managing a Kubernetes cluster with FluxCD. It follows the [Flux GitOps Toolkit](https://fluxcd.io/docs/components/) structure and recommended repository layout.

## Structure

```
├── clusters/
│   └── kalimdor/                  # Cluster name
│       ├── flux-system/           # Flux components
│       ├── apps.yaml              # References apps for this cluster
│       ├── infrastructure.yaml    # References infrastructure for this cluster
│       └── kustomization.yaml     # Main cluster kustomization
├── infrastructure/
│   ├── base/                      # Base infrastructure components
│   │   └── cilium/              # Base Cilium CNI configuration
│   └── kalimdor/                  # Cluster-specific infrastructure overlays
│       └── cilium/              # Cluster-specific Cilium overrides
└── apps/
    ├── base/                      # Base application definitions
    └── kalimdor/                  # Cluster-specific application overlays
```

## Components

### Cilium

The Cilium CNI configuration is based on the settings from the `terraform-proxmox-talos-k8s` project. It includes:

- Version: 1.16.8 (matching Talos v1.9.5 configuration)
- Configured for Talos Linux with kubeProxyReplacement set to false (as specifically requested)
- Includes L2 announcements, ingress controller, Envoy proxy, and Hubble monitoring
- Appropriate security context and capabilities

## Usage

This repository is meant to be used with Flux CD to automatically deploy and synchronize resources to your Kubernetes cluster. 

To bootstrap Flux on your cluster, follow the [Flux bootstrap guide](https://fluxcd.io/docs/installation/).
