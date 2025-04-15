// Resource Group Module
targetScope = 'subscription'

@description('The name of the resource group')
param name string

@description('The location of the resource group')
param location string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: name
  location: location
}

// Outputs
output name string = resourceGroup.name
output id string = resourceGroup.id
