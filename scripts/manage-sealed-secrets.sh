#!/bin/bash
#
# Secret Management Script for FluxCD with Sealed Secrets - Linux Version
# This script helps create, manage, and organize sealed secrets for FluxCD.
# It automates the process of creating, sealing, and organizing secrets.
#
# Created for Talos Kubernetes cluster with Cilium CNI
#
# Usage examples:
#   ./manage-sealed-secrets.sh -c -n mysql-credentials -ns databases
#   ./manage-sealed-secrets.sh -v -n mysql-credentials -ns databases
#   ./manage-sealed-secrets.sh -l

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
  local color=$1
  local message=$2
  echo -e "${color}${message}${NC}"
}

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to display help
show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo
  echo "Options:"
  echo "  -c, --create        Create a new sealed secret"
  echo "  -v, --view          View the contents of a sealed secret"
  echo "  -l, --list          List all sealed secrets"
  echo "  -n, --name NAME     Name of the secret (required for create, view)"
  echo "  -ns, --namespace NS Namespace for the secret (default: default)"
  echo "  -c, --cluster NAME  Cluster name (default: kalimdor)"
  echo "  -h, --help          Show this help message"
  echo
  echo "Examples:"
  echo "  $0 -c -n mysql-credentials -ns databases"
  echo "  $0 -v -n mysql-credentials -ns databases"
  echo "  $0 -l"
}

# Default values
ACTION=""
NAME=""
NAMESPACE="default"
CLUSTER_NAME="kalimdor"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--create)
      ACTION="create"
      shift
      ;;
    -v|--view)
      ACTION="view"
      shift
      ;;
    -l|--list)
      ACTION="list"
      shift
      ;;
    -n|--name)
      NAME="$2"
      shift 2
      ;;
    -ns|--namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    -c|--cluster)
      CLUSTER_NAME="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      print_color "$RED" "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Check prerequisites
if ! command_exists kubeseal; then
  print_color "$RED" "kubeseal is not installed!"
  print_color "$RED" "Please install kubeseal before using this script."
  print_color "$YELLOW" "You can install it from: https://github.com/bitnami-labs/sealed-secrets/releases"
  exit 1
fi

if ! command_exists kubectl; then
  print_color "$RED" "kubectl is not installed!"
  print_color "$RED" "Please install kubectl before using this script."
  exit 1
fi

# Get repository root
REPO_ROOT=$(pwd)

# Define secrets directory
SECRETS_BASE_DIR="$REPO_ROOT/clusters/$CLUSTER_NAME/sealed-secrets"

# Create secrets base directory if it doesn't exist
mkdir -p "$SECRETS_BASE_DIR"

# Create namespace directory if needed
NAMESPACE_DIR="$SECRETS_BASE_DIR/$NAMESPACE"
mkdir -p "$NAMESPACE_DIR"

# List all secrets
if [ "$ACTION" = "list" ]; then
  print_color "$CYAN" "Listing all sealed secrets:"
  print_color "$CYAN" "------------------------"
  
  if [ -z "$(find "$SECRETS_BASE_DIR" -name "*.yaml" -type f 2>/dev/null)" ]; then
    print_color "$YELLOW" "No sealed secrets found."
  else
    find "$SECRETS_BASE_DIR" -name "*.yaml" -type f | while read -r secret; do
      relative_path="${secret#$SECRETS_BASE_DIR/}"
      print_color "$NC" "- $relative_path"
    done
  fi
  
  exit 0
fi

# Validate parameters for other operations
if [ "$ACTION" != "list" ] && [ -z "$NAME" ]; then
  print_color "$RED" "Secret name is required for create and view operations."
  show_help
  exit 1
fi

# Define file paths
SECRET_PATH="$NAMESPACE_DIR/$NAME.yaml"
TEMPLATE_PATH="$NAMESPACE_DIR/$NAME.yaml.template"

# Create a new secret
if [ "$ACTION" = "create" ]; then
  print_color "$CYAN" "Creating new sealed secret: $NAME in namespace: $NAMESPACE"
  
  # Check if secret already exists
  if [ -f "$SECRET_PATH" ]; then
    read -p "Secret already exists. Overwrite? (y/n) " overwrite
    if [ "$overwrite" != "y" ]; then
      print_color "$YELLOW" "Operation canceled."
      exit 0
    fi
  fi
  
  # Create template
  cat > "$TEMPLATE_PATH" << EOF
apiVersion: v1
kind: Secret
metadata:
  name: $NAME
  namespace: $NAMESPACE
type: Opaque
stringData:
  # Add your key-value pairs below
  username: admin
  password: change-me-to-a-secure-password
  # Add any other key-value pairs you need
EOF
  
  print_color "$GREEN" "Template created at $TEMPLATE_PATH"
  
  # Open template for editing
  print_color "$YELLOW" "Opening template for editing..."
  if command_exists nano; then
    nano "$TEMPLATE_PATH"
  elif command_exists vim; then
    vim "$TEMPLATE_PATH"
  elif command_exists vi; then
    vi "$TEMPLATE_PATH"
  else
    print_color "$YELLOW" "No editor found. Please edit the template manually at $TEMPLATE_PATH"
    read -p "Press Enter when done editing..." 
  fi
  
  # Seal the secret
  print_color "$YELLOW" "Sealing secret..."
  
  # Check if we can connect to the cluster
  if ! kubectl cluster-info &>/dev/null; then
    print_color "$RED" "Could not connect to the Kubernetes cluster."
    print_color "$RED" "Make sure your kubeconfig is properly set up."
    exit 1
  fi
  
  # Seal the secret
  kubectl create --dry-run=client -f "$TEMPLATE_PATH" -o json | kubeseal --format yaml > "$SECRET_PATH"
  
  if [ $? -eq 0 ]; then
    print_color "$GREEN" "Secret sealed successfully at $SECRET_PATH"
    
    # Ask if user wants to delete the template
    read -p "Do you want to delete the template file? (y/n) " delete_template
    if [ "$delete_template" = "y" ]; then
      rm -f "$TEMPLATE_PATH"
      print_color "$GREEN" "Template deleted."
    else
      print_color "$YELLOW" "Template kept at $TEMPLATE_PATH"
      print_color "$RED" "WARNING: Do not commit the template file to git as it contains unencrypted secrets!"
    fi
  else
    print_color "$RED" "Error sealing secret."
    exit 1
  fi
  
  # Final instructions
  print_color "$CYAN" "
Next Steps:"
  print_color "$YELLOW" "1. Commit and push the sealed secret to your git repository:"
  print_color "$NC" "   git add $SECRET_PATH"
  print_color "$NC" "   git commit -m 'Add $NAME sealed secret for $NAMESPACE namespace'"
  print_color "$NC" "   git push"
  print_color "$YELLOW" "2. FluxCD will automatically apply the sealed secret to your cluster"
  print_color "$YELLOW" "3. The controller will decrypt it and create the actual Kubernetes secret"
fi

# View an existing secret
if [ "$ACTION" = "view" ]; then
  if [ ! -f "$SECRET_PATH" ]; then
    print_color "$RED" "Secret not found at $SECRET_PATH"
    exit 1
  fi
  
  print_color "$CYAN" "Viewing sealed secret: $NAME in namespace: $NAMESPACE"
  print_color "$CYAN" "--------------------------------------------"
  
  # Display the sealed secret
  cat "$SECRET_PATH"
  
  print_color "$YELLOW" "
Note: This is the sealed version of the secret. The actual values can only be decrypted within the cluster."
fi

# If no action was specified
if [ -z "$ACTION" ]; then
  print_color "$YELLOW" "No operation specified. Use -c/--create, -v/--view, or -l/--list."
  show_help
  exit 1
fi
