#Requires -Version 5.0
<#
.SYNOPSIS
    Secret management script for FluxCD with Sealed Secrets
.DESCRIPTION
    This script helps create, manage, and organize sealed secrets for FluxCD.
    It automates the process of creating, sealing, and organizing secrets.
.NOTES
    Created for Talos Kubernetes cluster with Cilium CNI
.EXAMPLE
    .\manage-sealed-secrets.ps1 -Create -Name "mysql-credentials" -Namespace "databases"
    Creates a new secret template and seals it
.EXAMPLE
    .\manage-sealed-secrets.ps1 -View -Name "mysql-credentials" -Namespace "databases"
    Displays the sealed secret (not the actual values, as they can only be decrypted in the cluster)
.EXAMPLE
    .\manage-sealed-secrets.ps1 -List
    Lists all sealed secrets in the repository
#>

param (
    [Parameter(Mandatory=$false)]
    [switch]$Create,
    
    [Parameter(Mandatory=$false)]
    [switch]$View,
    
    [Parameter(Mandatory=$false)]
    [switch]$List,
    
    [Parameter(Mandatory=$false)]
    [string]$Name,
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "default",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "kalimdor"
)

# Ensure we stop on errors
$ErrorActionPreference = "Stop"

function Write-ColorOutput {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [string]$ForegroundColor = "White"
    )
    
    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Test-Command {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Command
    )
    
    $exists = $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
    return $exists
}

# Check prerequisites
$kubesealInstalled = Test-Command "kubeseal"
if (-not $kubesealInstalled) {
    Write-ColorOutput "kubeseal is not installed or not in PATH!" "Red"
    Write-ColorOutput "Please install kubeseal before using this script." "Red"
    Write-ColorOutput "You can install it using one of these methods:" "Yellow"
    Write-ColorOutput "  - Chocolatey: choco install kubeseal" "Yellow"
    Write-ColorOutput "  - Download from: https://github.com/bitnami-labs/sealed-secrets/releases" "Yellow"
    exit 1
}

$kubectlInstalled = Test-Command "kubectl"
if (-not $kubectlInstalled) {
    Write-ColorOutput "kubectl is not installed or not in PATH!" "Red"
    Write-ColorOutput "Please install kubectl before using this script." "Red"
    exit 1
}

# Get repository root
$repoRoot = (Get-Location).Path

# Define secrets directory
$secretsBaseDir = Join-Path $repoRoot "clusters\$ClusterName\sealed-secrets"

# Create secrets base directory if it doesn't exist
if (-not (Test-Path $secretsBaseDir)) {
    New-Item -ItemType Directory -Path $secretsBaseDir -Force | Out-Null
}

# Create namespace directory if needed
$namespaceDir = Join-Path $secretsBaseDir $Namespace
if (-not (Test-Path $namespaceDir)) {
    New-Item -ItemType Directory -Path $namespaceDir -Force | Out-Null
}

# List all secrets
if ($List) {
    Write-ColorOutput "Listing all sealed secrets:" "Cyan"
    Write-ColorOutput "------------------------" "Cyan"
    
    $allSecrets = Get-ChildItem -Path $secretsBaseDir -Recurse -Filter "*.yaml"
    
    if ($allSecrets.Count -eq 0) {
        Write-ColorOutput "No sealed secrets found." "Yellow"
    } else {
        foreach ($secret in $allSecrets) {
            $relativePath = $secret.FullName.Substring($secretsBaseDir.Length + 1)
            Write-ColorOutput "- $relativePath" "White"
        }
    }
    
    exit 0
}

# Validate parameters for other operations
if (-not $List -and [string]::IsNullOrWhiteSpace($Name)) {
    Write-ColorOutput "Secret name is required for create and view operations." "Red"
    exit 1
}

# Define file paths
$secretPath = Join-Path $namespaceDir "$Name.yaml"
$templatePath = Join-Path $namespaceDir "$Name.yaml.template"

# Create a new secret
if ($Create) {
    Write-ColorOutput "Creating new sealed secret: $Name in namespace: $Namespace" "Cyan"
    
    # Check if secret already exists
    if (Test-Path $secretPath) {
        $overwrite = Read-Host "Secret already exists. Overwrite? (y/n)"
        if ($overwrite -ne "y") {
            Write-ColorOutput "Operation canceled." "Yellow"
            exit 0
        }
    }
    
    # Create template
    @"
apiVersion: v1
kind: Secret
metadata:
  name: $Name
  namespace: $Namespace
type: Opaque
stringData:
  # Add your key-value pairs below
  username: admin
  password: change-me-to-a-secure-password
  # Add any other key-value pairs you need
"@ | Out-File -FilePath $templatePath -Encoding ascii
    
    Write-ColorOutput "Template created at $templatePath" "Green"
    
    # Open template for editing
    Write-ColorOutput "Opening template for editing..." "Yellow"
    Start-Process notepad.exe -ArgumentList $templatePath -Wait
    
    # Seal the secret
    Write-ColorOutput "Sealing secret..." "Yellow"
    try {
        # Check if we can connect to the cluster
        kubectl cluster-info > $null
        if ($LASTEXITCODE -ne 0) {
            Write-ColorOutput "Could not connect to the Kubernetes cluster." "Red"
            Write-ColorOutput "Make sure your kubeconfig is properly set up." "Red"
            exit 1
        }
        
        # Seal the secret
        $sealedOutput = kubectl create --dry-run=client -f $templatePath -o json | kubeseal --format yaml
        $sealedOutput | Out-File -FilePath $secretPath -Encoding ascii
        
        Write-ColorOutput "Secret sealed successfully at $secretPath" "Green"
        
        # Ask if user wants to delete the template
        $deleteTemplate = Read-Host "Do you want to delete the template file? (y/n)"
        if ($deleteTemplate -eq "y") {
            Remove-Item -Path $templatePath -Force
            Write-ColorOutput "Template deleted." "Green"
        } else {
            Write-ColorOutput "Template kept at $templatePath" "Yellow"
            Write-ColorOutput "WARNING: Do not commit the template file to git as it contains unencrypted secrets!" "Red"
        }
    }
    catch {
        Write-ColorOutput "Error sealing secret: $_" "Red"
        exit 1
    }
}

# View an existing secret
elseif ($View) {
    if (-not (Test-Path $secretPath)) {
        Write-ColorOutput "Secret not found at $secretPath" "Red"
        exit 1
    }
    
    Write-ColorOutput "Viewing sealed secret: $Name in namespace: $Namespace" "Cyan"
    Write-ColorOutput "--------------------------------------------" "Cyan"
    
    try {
        # Display the sealed secret
        $secretContent = Get-Content -Path $secretPath -Raw
        Write-Output $secretContent
        
        Write-ColorOutput "`nNote: This is the sealed version of the secret. The actual values can only be decrypted within the cluster." "Yellow"
    }
    catch {
        Write-ColorOutput "Error viewing secret: $_" "Red"
        exit 1
    }
}

else {
    Write-ColorOutput "No operation specified. Use -Create, -View, or -List." "Yellow"
    exit 1
}

# Final instructions
if ($Create) {
    Write-ColorOutput "`nNext Steps:" "Cyan"
    Write-ColorOutput "1. Commit and push the sealed secret to your git repository:" "Yellow"
    Write-ColorOutput "   git add $secretPath" "White"
    Write-ColorOutput "   git commit -m 'Add $Name sealed secret for $Namespace namespace'" "White"
    Write-ColorOutput "   git push" "White"
    Write-ColorOutput "2. FluxCD will automatically apply the sealed secret to your cluster" "Yellow"
    Write-ColorOutput "3. The controller will decrypt it and create the actual Kubernetes secret" "Yellow"
}
