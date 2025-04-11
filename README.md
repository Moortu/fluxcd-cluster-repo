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
- Configured with L2 announcements for external IPs and LoadBalancer services
  - Enables direct external access to services without external load balancers
  - Uses ARP for L2 announcements on eth+ interfaces
  - Includes a default L2 announcement policy for all LoadBalancer services
- Network Policies for enhanced security
  - Fine-grained control over pod-to-pod communication
  - DNS-based policies for controlling external access
  - Example policies included but disabled by default
- Bandwidth Manager with BBR congestion control
  - Optimizes TCP connections for better performance
  - Prevents any single workload from consuming all bandwidth
- Host Firewall protection for node security
  - Protects the Kubernetes nodes themselves
  - Complements pod network policies
- Load Balancer IP Address Management (LB IPAM)
  - Automatic IP address management for LoadBalancer services
  - Topology-aware routing for better performance
- kubeProxyReplacement set to true with DSR mode and Maglev algorithm
- Native routing with direct node routes for optimal traffic flow
- Enhanced Hubble monitoring with detailed metrics
  - DNS, HTTP, TCP, ICMP, and flow metrics
  - UI and relay components for visualization
- Prometheus metrics enabled with ServiceMonitor support

### Traefik

Traefik serves as the ingress controller for the cluster. Configuration includes:

- Version: 35.0.0
- Deployed as a LoadBalancer service
- Configured with dashboard and API access
- Integration with Cilium CNI
- Resource limits and requests for optimal performance

### Metrics Server

The Metrics Server collects resource metrics from nodes and pods, enabling features like Horizontal Pod Autoscaler and providing metrics for `kubectl top` commands:

- Version: 3.11.0
- Configured for Talos with kubelet-insecure-tls flag
- 15-second metric resolution for more responsive autoscaling
- Prometheus-compatible metrics endpoint
- Resource limits optimized for home cluster usage

## Usage

This repository is meant to be used with Flux CD to automatically deploy and synchronize resources to your Kubernetes cluster. 

To bootstrap Flux on your cluster, follow the [Flux bootstrap guide](https://fluxcd.io/docs/installation/).
