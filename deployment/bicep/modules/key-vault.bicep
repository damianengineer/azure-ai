// Key Vault Module

@description('The name of the Key Vault')
param name string

@description('The location of the Key Vault')
param location string

@description('The object ID of the current user/service principal for Key Vault access')
param currentUserObjectId string

@description('The SKU name of the Key Vault')
param skuName string = 'standard'

// Create Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: name
  location: location
  properties: {
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
    tenantId: subscription().tenantId
    sku: {
      name: skuName
      family: 'A'
    }
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    networkAcls: {
      defaultAction: 'Allow'  // For local development, allowing access from all networks
      bypass: 'AzureServices'
    }
    accessPolicies: [
      {
        objectId: currentUserObjectId
        tenantId: subscription().tenantId
        permissions: {
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          certificates: [
            'all'
          ]
        }
      }
    ]
  }
}

// Outputs
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultId string = keyVault.id
