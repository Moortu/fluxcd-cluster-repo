# Flux CD Repository for Kubernetes Cluster

This repository contains the GitOps configurations for managing a Talos Kubernetes cluster with Cilium CNI using FluxCD. It follows the [Flux GitOps Toolkit](https://fluxcd.io/docs/components/) structure and recommended repository layout.

## Structure

```
├── clusters/
│   └── kalimdor/                  # Cluster name
│       ├── flux-system/           # Flux components
│       ├── sealed-secrets/         # Sealed Secrets by namespace
│       ├── apps.yaml              # References apps for this cluster
│       ├── infrastructure.yaml    # References infrastructure for this cluster
│       └── kustomization.yaml     # Main cluster kustomization
├── infrastructure/
│   ├── base/                      # Base infrastructure components
│   │   ├── cilium/                # Base Cilium CNI configuration
│   │   └── sealed-secrets/        # Sealed Secrets controller
│   └── kalimdor/                  # Cluster-specific infrastructure overlays
│       └── cilium/                # Cluster-specific Cilium overrides
├── apps/
│   ├── base/                      # Base application definitions
│   └── kalimdor/                  # Cluster-specific application overlays
├── scripts/                       # Utility scripts
│   ├── manage-sealed-secrets.ps1  # Windows script for sealed secrets
│   └── manage-sealed-secrets.sh   # Linux script for sealed secrets
└── .gitignore                    # Git ignore file
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

## Secret Management with Sealed Secrets

This repository uses Bitnami Sealed Secrets for managing Kubernetes secrets. The setup includes:

- Sealed Secrets controller deployed via Helm
- Encrypted secrets that can be safely stored in Git
- Kubernetes-native approach with no external dependencies
- Automatic decryption within the cluster

### How Sealed Secrets Work

1. Secrets are encrypted using the controller's public key
2. Encrypted secrets are stored in the Git repository
3. When applied to the cluster, the controller decrypts them using its private key
4. Only the controller running in your cluster can decrypt the secrets

### Secret Management Scripts

Utility scripts are provided in the `scripts/` directory for both Windows (PowerShell) and Linux (Bash) users:

#### Windows PowerShell Script

**manage-sealed-secrets.ps1**: Script for sealed secret management
```powershell
# Create a new sealed secret
./scripts/manage-sealed-secrets.ps1 -Create -Name "mysql-credentials" -Namespace "databases"

# View a sealed secret
./scripts/manage-sealed-secrets.ps1 -View -Name "mysql-credentials" -Namespace "databases"

# List all sealed secrets
./scripts/manage-sealed-secrets.ps1 -List
```

#### Linux Bash Script

**manage-sealed-secrets.sh**: Script for sealed secret management
```bash
# Make the script executable if needed
chmod +x ./scripts/manage-sealed-secrets.sh

# Create a new sealed secret
./scripts/manage-sealed-secrets.sh -c -n mysql-credentials -ns databases

# View a sealed secret
./scripts/manage-sealed-secrets.sh -v -n mysql-credentials -ns databases

# List all sealed secrets
./scripts/manage-sealed-secrets.sh -l

# Show help
./scripts/manage-sealed-secrets.sh -h
```

### Secret Organization

Sealed Secrets are organized by namespace under `clusters/kalimdor/sealed-secrets/`. For example:
```
clusters/kalimdor/sealed-secrets/
├── monitoring/
│   └── grafana-admin.yaml
├── databases/
│   └── postgres-creds.yaml
└── default/
    └── example-secret.yaml
```

### Backing Up the Sealed Secrets Key

The Sealed Secrets controller generates a private key that should be backed up for disaster recovery. To back up the key:

```bash
# Export the private key
kubectl get secret -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealed-secrets-key.yaml

# Store this file securely outside the cluster
```

## Usage

This repository is meant to be used with Flux CD to automatically deploy and synchronize resources to your Kubernetes cluster. 

To bootstrap Flux on your cluster, follow the [Flux bootstrap guide](https://fluxcd.io/docs/installation/).
