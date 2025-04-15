// Storage Account Module

@description('The name of the Storage Account')
param name string

@description('The location of the Storage Account')
param location string

@description('The name of the Key Vault')
param keyVaultName string

@description('Enable hierarchical namespace for Data Lake Storage Gen2')
param enableHierarchicalNamespace bool = false

// Validate storage account name (Azure has strict naming rules)
var sanitizedName = toLower(replace(name, '-', ''))

// Create Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: sanitizedName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'  // Standard locally redundant storage for dev environments
  }
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    isHnsEnabled: enableHierarchicalNamespace
  }
}

// Create default container for AI training data
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: 'default'
  parent: storageAccount
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: 'ai-training-data'
  parent: blobService
  properties: {
    publicAccess: 'None'
  }
}

// Get reference to Key Vault for storing secrets
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// Store Storage Account connection string in Key Vault
resource storageConnectionString 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: '${name}-connection-string'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  }
}

// Store Storage Account key in Key Vault
resource storageKey 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: '${name}-key'
  properties: {
    value: storageAccount.listKeys().keys[0].value
  }
}

// Outputs
output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
output containerName string = container.name
output connectionStringSecretUri string = storageConnectionString.properties.secretUri
