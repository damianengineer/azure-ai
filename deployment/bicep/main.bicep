// main.bicep - Main deployment file for Azure AI resources
// This template deploys a resource group, Key Vault, Storage Account, and AI Services resource

targetScope = 'subscription' // Required to create a resource group

// Parameters
@description('The location for all resources')
param location string = 'eastus'

@description('Base name to use for all resources (will be used with suffixes)')
param baseName string

@description('Environment name (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

@description('The object ID of the current user/service principal for Key Vault access')
param currentUserObjectId string

// Variables
var resourceGroupName = '${baseName}-${environmentName}-rg'
var uniqueSuffix = substring(uniqueString(subscription().id, baseName, environmentName), 0, 6)

// Create Resource Group directly
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}

// Key Vault Module - Deploy first to store secrets
module keyVault 'modules/key-vault.bicep' = {
  name: 'keyVaultDeployment'
  scope: rg
  params: {
    name: '${baseName}-${environmentName}-kv-${uniqueSuffix}' // KV names must be globally unique
    location: location
    currentUserObjectId: currentUserObjectId
  }
}

// Storage Account Module
module storageAccount 'modules/storage-account.bicep' = {
  name: 'storageAccountDeployment'
  scope: rg
  params: {
    name: '${baseName}${environmentName}sa${uniqueSuffix}' // Storage account names must be globally unique and lowercase alphanumeric
    location: location
    keyVaultName: keyVault.outputs.keyVaultName
  }
}

// AI Services Module
module aiServices 'modules/ai-services.bicep' = {
  name: 'aiServicesDeployment'
  scope: rg
  params: {
    name: '${baseName}-${environmentName}-ai'
    location: location
    keyVaultName: keyVault.outputs.keyVaultName
    storageAccountName: storageAccount.outputs.storageAccountName
  }
}

// Outputs
output resourceGroupName string = rg.name
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultUri string = keyVault.outputs.keyVaultUri
output storageAccountName string = storageAccount.outputs.storageAccountName
output aiServicesName string = aiServices.outputs.aiServicesName

