# FluxCD Repository Installation Guide

This guide provides instructions for bootstrapping FluxCD on your Talos Kubernetes cluster and deploying Cilium as the CNI.

## Prerequisites

- A working Kubernetes cluster (preferably Talos-based, as configured in the terraform-proxmox-talos-k8s project)
- `kubectl` installed and configured to access your cluster
- `flux` CLI installed

## Bootstrapping FluxCD

1. Install the Flux CLI by following the [official installation guide](https://fluxcd.io/docs/installation/).

2. Bootstrap Flux onto your cluster:

```bash
flux bootstrap github \
  --owner=<your-github-username> \
  --repository=fluxcd_repo \
  --branch=main \
  --path=./clusters/default \
  --personal
```

Or if you're using a different Git provider, adjust the command accordingly.

## Verifying the Installation

Once Flux is bootstrapped, it will automatically start reconciling the resources defined in this repository.

Check the status of your Flux components:

```bash
kubectl get pods -n flux-system
```

Check the status of the Cilium installation:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=cilium
```

## Monitoring Resources

You can monitor the synchronization status with:

```bash
flux get kustomizations
flux get helmreleases
```

## Troubleshooting

If you encounter issues, check the Flux logs:

```bash
flux logs
```

## Cilium Configuration

The Cilium configuration in this repository is based on the settings from the terraform-proxmox-talos-k8s project:

- Using Cilium version 1.15.6
- Configured for kube-proxy replacement
- Hubble enabled for observability
- Prometheus metrics enabled
