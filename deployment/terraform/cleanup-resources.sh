#!/bin/bash
#
# Script to clean up deployed Azure resources
# Uses Terraform destroy to properly remove all resources
#

set -e  # Exit immediately if a command exits with a non-zero status

# Color codes for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function for logging
log() {
  local level=$1
  local message=$2
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  
  case $level in
    "INFO")
      echo -e "${BLUE}[INFO]${NC} ${timestamp} - $message"
      ;;
    "SUCCESS")
      echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - $message"
      ;;
    "WARNING")
      echo -e "${YELLOW}[WARNING]${NC} ${timestamp} - $message"
      ;;
    "ERROR")
      echo -e "${RED}[ERROR]${NC} ${timestamp} - $message"
      ;;
    *)
      echo -e "${timestamp} - $message"
      ;;
  esac
}

# Function to auto-detect resource suffix
detect_resource_suffix() {
  local suffix=""

  # First, try to extract from deployment-outputs.json
  if [ -f "deployment-outputs.json" ]; then
    suffix=$(jq -r '.deployment_info.value.suffix // ""' deployment-outputs.json)
    if [ -n "$suffix" ]; then
      echo "$suffix"
      return 0
    fi
  fi

  # Next, try to extract from terraform.tfstate
  if [ -f "terraform.tfstate" ]; then
    suffix=$(grep -o '"random_string.suffix.result": "[^"]*' terraform.tfstate | cut -d'"' -f4)
    if [ -n "$suffix" ]; then
      echo "$suffix"
      return 0
    fi
  fi

  # If no suffix found
  return 1
}

# Require dependencies
if ! command -v terraform &> /dev/null; then
  log "ERROR" "Terraform is not installed. Please install Terraform."
  exit 1
fi

if ! command -v az &> /dev/null; then
  log "ERROR" "Azure CLI is not installed. Please install Azure CLI."
  exit 1
fi

if ! command -v jq &> /dev/null; then
  log "ERROR" "jq is not installed. Please install jq."
  exit 1
fi

# Initialize variables
FORCE=false
RESOURCE_SUFFIX=""
CLEAN_STATE=false

# Process command line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --force) FORCE=true ;;
    --clean-state) CLEAN_STATE=true ;;
    *)
      if [[ "$1" =~ ^[a-z0-9]{8}$ ]]; then
        RESOURCE_SUFFIX="$1"
      else
        log "ERROR" "Invalid argument: $1"
        echo "Usage: $0 [resource-suffix] [--force] [--clean-state]"
        exit 1
      fi
      ;;
  esac
  shift
done

# Detect resource suffix if not provided
if [ -z "$RESOURCE_SUFFIX" ]; then
  if ! RESOURCE_SUFFIX=$(detect_resource_suffix); then
    log "ERROR" "Could not automatically detect resource suffix"
    echo "Please provide the resource suffix or ensure Terraform state files exist"
    echo "Usage: $0 [resource-suffix] [--force] [--clean-state]"
    exit 1
  else
    log "INFO" "Auto-detected resource suffix: $RESOURCE_SUFFIX"
  fi
fi

# Construct resource group name for display purposes
RESOURCE_GROUP_NAME="dev-rg-aiservices-$RESOURCE_SUFFIX"

log "INFO" "Preparing to clean up resources with suffix: $RESOURCE_SUFFIX"
log "INFO" "Expected Resource Group: $RESOURCE_GROUP_NAME"

# Ensure Azure CLI is logged in
log "INFO" "Verifying Azure CLI login..."
az account show &> /dev/null
if [ $? -ne 0 ]; then
  log "WARNING" "Not logged in. Running az login..."
  az login
fi

# Confirm destruction
if [ "$FORCE" = false ]; then
  log "WARNING" "This will permanently destroy all resources deployed by Terraform"
  read -p "Are you sure you want to proceed? (yes/no): " CONFIRM
  if [ "$CONFIRM" != "yes" ]; then
    log "INFO" "Operation canceled."
    exit 0
  fi
fi

# Initialize Terraform if .terraform directory doesn't exist
if [ ! -d ".terraform" ]; then
  log "INFO" "Initializing Terraform..."
  terraform init
  
  if [ $? -ne 0 ]; then
    log "ERROR" "Failed to initialize Terraform. Please check your Terraform configuration."
    exit 1
  fi
fi

# Create terraform.tfvars if it doesn't exist
if [ ! -f "terraform.tfvars" ] && [ -f "deployment-outputs.json" ]; then
  log "INFO" "Recreating terraform.tfvars from deployment outputs..."
  ENV=$(jq -r '.deployment_info.value.environment // "dev"' deployment-outputs.json)
  LOCATION=$(jq -r '.deployment_info.value.location // "eastus"' deployment-outputs.json)
  
  cat > terraform.tfvars << EOL
environment = "${ENV}"
environment_prefix = "${ENV}"
location = "${LOCATION}"
project_name = "AzureAIDeployment"
tags = {
  Environment = "${ENV}"
  Project = "AzureAIDeployment"
  ManagedBy = "Terraform"
  Owner = "AI Team"
  DeploymentScript = "cleanup.sh"
}
EOL
  log "SUCCESS" "Created terraform.tfvars from deployment outputs"
fi

# Run terraform destroy
log "INFO" "Running terraform destroy..."
if [ "$FORCE" = true ]; then
  terraform destroy -auto-approve
else
  terraform destroy
fi

# Check if terraform destroy was successful
if [ $? -eq 0 ]; then
  log "SUCCESS" "Terraform destroy completed successfully"
else
  log "ERROR" "Terraform destroy encountered issues"
  read -p "Do you want to force resource group deletion directly? (yes/no): " FORCE_DELETE
  if [ "$FORCE_DELETE" = "yes" ]; then
    log "INFO" "Attempting to delete resource group directly: $RESOURCE_GROUP_NAME"
    
    # Check if resource group exists
    if az group show --name "$RESOURCE_GROUP_NAME" --output none 2>/dev/null; then
      # Delete resource group directly
      az group delete --name "$RESOURCE_GROUP_NAME" --yes --output none
      
      if [ $? -eq 0 ]; then
        log "SUCCESS" "Resource group deletion initiated"
        log "INFO" "Resource group deletion may take several minutes to complete"
      else
        log "ERROR" "Failed to delete resource group"
      fi
    else
      log "INFO" "Resource group not found or already deleted"
    fi
  fi
fi

# Clean up local files if requested or forced
if [ "$CLEAN_STATE" = true ] || [ "$FORCE" = true ]; then
  log "INFO" "Cleaning up local Terraform state files..."
  
  # List of files and directories to remove
  STATE_FILES=(
    ".terraform"
    "terraform.tfstate"
    "terraform.tfstate.backup"
    "tfplan"
    "deployment-outputs.json"
    "terraform.tfvars"
    "deployment_config.json"
  )
  
  # Remove state files
  for item in "${STATE_FILES[@]}"; do
    if [ -f "$item" ] || [ -d "$item" ]; then
      rm -rf "$item"
      log "INFO" "Removed: $item"
    fi
  done
  
  log "SUCCESS" "Terraform state files cleaned up"
else
  log "INFO" "Local Terraform state files preserved for future operations"
  log "INFO" "Use --clean-state option to remove local state files"
fi

log "SUCCESS" "Cleanup process completed"
log "INFO" "All resources with suffix '$RESOURCE_SUFFIX' have been destroyed"
