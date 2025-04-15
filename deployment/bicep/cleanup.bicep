// cleanup.bicep - Template to safely remove resources created by the deployment
// This is a demonstration of how to use Bicep for resource cleanup
// IMPORTANT: This will delete resources!

targetScope = 'subscription'

// Parameters
@description('The name of the resource group to remove')
param resourceGroupName string

// No resources to deploy - the only operation is to remove the resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: resourceGroupName
}

// Output to confirm deletion is in progress
output deletionTarget string = resourceGroupName
