#!/bin/bash
#
# Terraform deployment script for Azure AI infrastructure
# This script handles initialization, validation, planning, and application of Terraform
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

# Function to check if terraform is installed
check_terraform() {
  if ! command -v terraform &> /dev/null; then
    log "ERROR" "Terraform is not installed. Please install it before running this script."
    exit 1
  fi
  
  local terraform_version=$(terraform version -json | jq -r '.terraform_version')
  log "INFO" "Terraform version: $terraform_version"
}

# Function to check if Azure CLI is installed and logged in
check_azure_cli() {
  if ! command -v az &> /dev/null; then
    log "ERROR" "Azure CLI is not installed. Please install it before running this script."
    exit 1
  fi
  
  # Check if logged in
  if ! az account show &> /dev/null; then
    log "WARNING" "Not logged in to Azure. Running az login..."
    az login
  fi
  
  local subscription=$(az account show --query name -o tsv)
  local account=$(az account show --query user.name -o tsv)
  log "INFO" "Using Azure subscription: $subscription ($account)"
}

# Function to set variables with user input
get_variables() {
  # Default values
  ENV=${ENV:-"dev"}
  LOCATION=${LOCATION:-"eastus"}
  
  # Ask for environment if not set
  if [ -z "$ENV" ]; then
    read -p "Enter environment (dev, test, staging, prod) [dev]: " ENV
    ENV=${ENV:-"dev"}
  fi
  
  # Ask for location if not set
  if [ -z "$LOCATION" ]; then
    read -p "Enter Azure region (eastus, westus2, etc.) [eastus]: " LOCATION
    LOCATION=${LOCATION:-"eastus"}
  fi
  
  # Validate inputs
  case $ENV in
    dev|test|staging|prod)
      ;;
    *)
      log "ERROR" "Invalid environment. Must be one of: dev, test, staging, prod"
      exit 1
      ;;
  esac
  
  log "INFO" "Deploying to environment: $ENV in region: $LOCATION"
}

# Function to create a variables file
create_tfvars() {
  log "INFO" "Creating terraform.tfvars file"
  
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
  DeploymentScript = "deploy.sh"
}
EOL

  log "SUCCESS" "Created terraform.tfvars file"
}

# Function to initialize Terraform
init_terraform() {
  log "INFO" "Initializing Terraform..."
  
  # Run terraform init
  terraform init -upgrade
  
  if [ $? -ne 0 ]; then
    log "ERROR" "Terraform initialization failed"
    exit 1
  fi
  
  log "SUCCESS" "Terraform initialization complete"
}

# Function to validate Terraform configuration
validate_terraform() {
  log "INFO" "Validating Terraform configuration..."
  
  # Run terraform validate
  terraform validate
  
  if [ $? -ne 0 ]; then
    log "ERROR" "Terraform validation failed"
    exit 1
  fi
  
  log "SUCCESS" "Terraform configuration is valid"
}

# Function to generate and review a Terraform plan
plan_terraform() {
  log "INFO" "Generating Terraform plan..."
  
  # Run terraform plan and save to file
  terraform plan -out=tfplan -var-file=terraform.tfvars
  
  if [ $? -ne 0 ]; then
    log "ERROR" "Terraform plan generation failed"
    exit 1
  fi
  
  log "SUCCESS" "Terraform plan generated successfully"
  
  # Ask for confirmation before applying
  read -p "Do you want to review the plan details? (y/n) [y]: " REVIEW
  REVIEW=${REVIEW:-"y"}
  
  if [[ $REVIEW == "y" ]]; then
    terraform show tfplan
  fi
}

# Function to apply the Terraform plan
apply_terraform() {
  log "WARNING" "Ready to apply Terraform plan to create/modify infrastructure"
  read -p "Do you want to continue with the deployment? (y/n) [n]: " CONTINUE
  CONTINUE=${CONTINUE:-"n"}
  
  if [[ $CONTINUE != "y" ]]; then
    log "INFO" "Deployment cancelled by user"
    exit 0
  fi
  
  log "INFO" "Applying Terraform plan..."
  
  # Apply the saved plan
  terraform apply tfplan
  
  if [ $? -ne 0 ]; then
    log "ERROR" "Terraform apply failed"
    exit 1
  fi
  
  log "SUCCESS" "Terraform apply completed successfully"
}

# Function to display output variables and save to a file
show_outputs() {
  log "INFO" "Retrieving deployment outputs..."
  
  # Get outputs in JSON format
  terraform output -json > deployment-outputs.json
  
  if [ $? -ne 0 ]; then
    log "WARNING" "Failed to save outputs to file"
  else
    log "SUCCESS" "Deployment outputs saved to deployment-outputs.json"
  fi
  
  # Extract key information using jq instead of terraform output
  RESOURCE_SUFFIX=$(jq -r '.deployment_info.value.suffix // ""' deployment-outputs.json)
  RESOURCE_GROUP=$(jq -r '.resource_group.value.name // ""' deployment-outputs.json)
  KEY_VAULT=$(jq -r '.key_vault.value.name // ""' deployment-outputs.json)
  AI_SERVICES=$(jq -r '.ai_services.value.name // ""' deployment-outputs.json)
  
  echo -e "\n${GREEN}======== DEPLOYMENT SUMMARY ========${NC}"
  echo -e "${BLUE}Environment:${NC} $ENV"
  echo -e "${BLUE}Location:${NC} $LOCATION"
  echo -e "${BLUE}Resource Group:${NC} $RESOURCE_GROUP"
  echo -e "${BLUE}Resource Suffix:${NC} $RESOURCE_SUFFIX"
  echo -e "${BLUE}Key Vault:${NC} $KEY_VAULT"
  echo -e "${BLUE}AI Services:${NC} $AI_SERVICES"
  echo -e "${GREEN}=====================================${NC}"
  
  # Create a configuration file for the Python script
  cat > deployment_config.json << EOL
{
  "KEY_VAULT_NAME": "${KEY_VAULT}",
  "AI_SERVICES_NAME": "${AI_SERVICES}"
}
EOL
  log "SUCCESS" "Created deployment_config.json for Python script"
  
  echo -e "\nTo analyze sentiment, run: python3 ./azure_ai_sentiment_analysis.py"
  echo -e "To clean up resources, run: ./cleanup-resources.sh $RESOURCE_SUFFIX"
}

# Main execution
main() {
  log "INFO" "Starting deployment process"
  
  check_terraform
  check_azure_cli
  get_variables
  create_tfvars
  init_terraform
  validate_terraform
  plan_terraform
  apply_terraform
  show_outputs
  
  log "SUCCESS" "Deployment process completed"
}

# Run the main function
main
