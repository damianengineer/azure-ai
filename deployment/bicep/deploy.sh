#!/bin/bash

# Get the current user's Object ID for Key Vault access policies
CURRENT_USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
echo "Current user Object ID: $CURRENT_USER_OBJECT_ID"

# Create a temporary parameters file with the user's Object ID
cp main.parameters.json main.parameters.temp.json

# For macOS compatibility (detect OS and use the right version of sed)
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS version (using perl instead of sed for better compatibility)
  perl -pi -e "s/REPLACE_WITH_YOUR_USER_OBJECT_ID/$CURRENT_USER_OBJECT_ID/g" main.parameters.temp.json
else
  # Linux version
  sed -i "s/REPLACE_WITH_YOUR_USER_OBJECT_ID/$CURRENT_USER_OBJECT_ID/g" main.parameters.temp.json
fi

# Make sure modules directory exists
echo "Checking for modules directory..."
if [ ! -d "modules" ]; then
  echo "Creating modules directory..."
  mkdir -p modules
fi

# List files to verify they exist
echo "Verifying module files exist..."
ls -la modules/

# Deploy the Bicep template
echo "Deploying Azure resources..."
deployment_output=$(az deployment sub create \
  --name "AIProjectDeployment-$(date +%Y%m%d%H%M%S)" \
  --location eastus \
  --template-file main.bicep \
  --parameters @main.parameters.temp.json \
  --output json)

# Check deployment status
if [ $? -eq 0 ]; then
  echo "Deployment completed successfully!"
  
  # Extract outputs
  RESOURCE_GROUP_NAME=$(echo "$deployment_output" | jq -r '.properties.outputs.resourceGroupName.value')
  KEY_VAULT_NAME=$(echo "$deployment_output" | jq -r '.properties.outputs.keyVaultName.value')
  AI_SERVICES_NAME=$(echo "$deployment_output" | jq -r '.properties.outputs.aiServicesName.value')
  STORAGE_ACCOUNT_NAME=$(echo "$deployment_output" | jq -r '.properties.outputs.storageAccountName.value')

  # Create a configuration file for the Python script
  cat > deployment_config.json << EOF
{
  "RESOURCE_GROUP_NAME": "$RESOURCE_GROUP_NAME",
  "KEY_VAULT_NAME": "$KEY_VAULT_NAME",
  "AI_SERVICES_NAME": "$AI_SERVICES_NAME",
  "STORAGE_ACCOUNT_NAME": "$STORAGE_ACCOUNT_NAME"
}
EOF

  # Display deployment outputs
  echo "Deployment Outputs:"
  echo "$deployment_output" | jq '.properties.outputs'
else
  echo "Deployment failed!"
  exit 1
fi

# Clean up temporary file
rm main.parameters.temp.json
