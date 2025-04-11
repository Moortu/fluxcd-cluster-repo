# Sealed Secrets

This directory contains Sealed Secrets for the Kubernetes cluster. Sealed Secrets are encrypted Kubernetes secrets that can be safely stored in Git repositories.

## Directory Structure

```
sealed-secrets/
├── default/          # Secrets for the default namespace
├── databases/        # Secrets for database applications
└── monitoring/       # Secrets for monitoring tools
```

## Managing Sealed Secrets

Use the provided scripts to create, view, and manage sealed secrets:

### Windows PowerShell

```powershell
# Create a new sealed secret
.\scripts\manage-sealed-secrets.ps1 -Create -Name "mysql-credentials" -Namespace "databases"

# View a sealed secret
.\scripts\manage-sealed-secrets.ps1 -View -Name "mysql-credentials" -Namespace "databases"

# List all sealed secrets
.\scripts\manage-sealed-secrets.ps1 -List
```

### Linux Bash

```bash
# Make the script executable if needed
chmod +x ./scripts/manage-sealed-secrets.sh

# Create a new sealed secret
./scripts/manage-sealed-secrets.sh -c -n mysql-credentials -ns databases

# View a sealed secret
./scripts/manage-sealed-secrets.sh -v -n mysql-credentials -ns databases

# List all sealed secrets
./scripts/manage-sealed-secrets.sh -l
```

## Important Notes

1. Never commit unencrypted secrets to the repository
2. Secret template files (*.yaml.template) are excluded by .gitignore
3. Only sealed secrets (*.yaml) should be committed
4. The Sealed Secrets controller is responsible for decrypting secrets in the cluster
