#!/bin/bash
# cleanup.sh - Script to remove all Azure resources deployed by Bicep

# Resource names from the deployment
RESOURCE_GROUP="aiproject-dev-rg"  # Replace with your resource group name if different
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Confirm before proceeding
echo "⚠️  WARNING: This will delete all resources in the resource group: $RESOURCE_GROUP"
echo "This action cannot be undone!"
read -p "Do you want to continue? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo "Starting resource cleanup..."

# First, remove any special locks that might prevent deletion
echo "Checking for resource locks..."
LOCKS=$(az lock list --resource-group $RESOURCE_GROUP --query "[].id" -o tsv)
if [ -n "$LOCKS" ]; then
    echo "Removing resource locks..."
    for LOCK_ID in $LOCKS; do
        echo "Removing lock: $LOCK_ID"
        az lock delete --ids "$LOCK_ID"
    done
fi

# Check if Key Vault exists and if soft-delete is enabled
KEY_VAULT_NAME=$(az keyvault list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)
if [ -n "$KEY_VAULT_NAME" ]; then
    echo "Preparing Key Vault $KEY_VAULT_NAME for deletion..."
    
    # For Key Vaults with soft-delete enabled, we need to update access policies
    # This ensures we can fully delete the resource group
    az keyvault set-policy --name $KEY_VAULT_NAME \
        --resource-group $RESOURCE_GROUP \
        --object-id $(az ad signed-in-user show --query id -o tsv) \
        --certificate-permissions purge delete \
        --key-permissions purge delete \
        --secret-permissions purge delete \
        --storage-permissions purge delete
fi

# Delete the resource group and all its resources
echo "Deleting resource group: $RESOURCE_GROUP"
az group delete --name $RESOURCE_GROUP --yes --no-wait

echo "Resource deletion has been initiated."
echo "You can check deletion status with: az group show -n $RESOURCE_GROUP"

# Optionally, wait for deletion to complete
echo "Waiting for resource group deletion to complete..."
while az group show --name $RESOURCE_GROUP &>/dev/null; do
    echo "Resource group $RESOURCE_GROUP still exists, waiting..."
    sleep 10
done

echo "✅ Resource group $RESOURCE_GROUP has been successfully deleted."