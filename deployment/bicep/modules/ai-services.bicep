// AI Services Module

@description('The name of the AI Services resource')
param name string

@description('The location of the AI Services resource')
param location string

@description('The name of the Key Vault')
param keyVaultName string

@description('The name of the Storage Account')
param storageAccountName string

@description('The SKU name of the AI Services resource')
@allowed([
  'F0'  // Free tier
  'S0'  // Standard tier
])
param skuName string = 'S0'

// Get reference to existing resources
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

// Create a system-assigned managed identity for the AI service
resource aiServices 'Microsoft.CognitiveServices/accounts@2022-12-01' = {
  name: name
  location: location
  sku: {
    name: skuName
  }
  kind: 'CognitiveServices' // Multi-service resource
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: toLower(name)
    networkAcls: {
      defaultAction: 'Allow' // For development, allowing access from all networks
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
}

// Grant the AI Service's managed identity access to the Storage Account
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiServices.id, storageAccount.id, 'StorageBlobDataContributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe') // Storage Blob Data Contributor role
    principalId: aiServices.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Store AI Services key in Key Vault
resource aiServicesKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: '${name}-key'
  properties: {
    value: aiServices.listKeys().key1
  }
}

// Store AI Services endpoint in Key Vault
resource aiServicesEndpoint 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: '${name}-endpoint'
  properties: {
    value: aiServices.properties.endpoint
  }
}

// Outputs
output aiServicesName string = aiServices.name
output aiServicesId string = aiServices.id
output aiServicesEndpoint string = aiServices.properties.endpoint
