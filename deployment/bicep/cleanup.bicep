// cleanup.bicep - Template to safely remove resources created by the deployment
// This is a demonstration of how to use Bicep for resource cleanup
// IMPORTANT: This will delete resources!

targetScope = 'subscription'

// Parameters
@description('The name of the resource group to remove')
param resourceGroupName string

// Optional: Add a confirmation parameter to prevent accidental deletion
@description('Confirm resource group deletion')
@allowed([
  'yes',
  'no'
])
param confirmDeletion string = 'no'

// Resource group deletion
resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: resourceGroupName
}

// Conditional deletion
resource resourceGroupDeletion 'Microsoft.Resources/deployments@2022-09-01' = if (confirmDeletion == 'yes') {
  name: 'resourceGroupDeletion'
  location: resourceGroup.location
  properties: {
    mode: 'Complete'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#',
      contentVersion: '1.0.0.0',
      resources: []
    }
  }
}

// Output to confirm deletion is in progress
output deletionTarget string = resourceGroupName
