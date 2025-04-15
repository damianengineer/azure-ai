# Output the deployment identification info
output "deployment_info" {
  value = {
    timestamp   = timestamp()
    environment = var.environment
    suffix      = random_string.suffix.result
    location    = var.location
  }
  description = "Deployment metadata for tracking purposes"
}

# Output resource group details
output "resource_group" {
  value = {
    id       = azurerm_resource_group.rg.id
    name     = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
  }
  description = "Resource group details"
}

# Output Key Vault details (intent: do not include secrets in output)
output "key_vault" {
  value = {
    id   = azurerm_key_vault.kv.id
    name = azurerm_key_vault.kv.name
    uri  = azurerm_key_vault.kv.vault_uri
  }
  description = "Key Vault details"
  sensitive   = false
}

# Output Storage Account details ((intent: do not include secrets in output))
output "storage_account" {
  value = {
    id             = azurerm_storage_account.sa.id
    name           = azurerm_storage_account.sa.name
    primary_access = azurerm_storage_account.sa.primary_access_key != null ? "configured" : "not-configured"
    container      = azurerm_storage_container.container.name
  }
  description = "Storage Account details"
  sensitive   = false
}

# Output AI Services details (intent: do not include secrets in output)
output "ai_services" {
  value = {
    id              = azurerm_cognitive_account.ai_services.id
    name            = azurerm_cognitive_account.ai_services.name
    endpoint        = azurerm_cognitive_account.ai_services.endpoint
    identity        = azurerm_cognitive_account.ai_services.identity.0.principal_id
    primary_access  = azurerm_cognitive_account.ai_services.primary_access_key != null ? "configured" : "not-configured"
  }
  description = "AI Services details"
  sensitive   = false
}

# Output Key Vault secrets (names only, not values for security)
output "key_vault_secrets" {
  value = {
    ai_key              = azurerm_key_vault_secret.ai_key.name
    ai_endpoint         = azurerm_key_vault_secret.ai_endpoint.name
    storage_connection  = azurerm_key_vault_secret.storage_connection.name
  }
  description = "The names of secrets stored in Key Vault"
}

# Output for use in cleanup scripts
output "cleanup_info" {
  value = {
    resource_group_name = azurerm_resource_group.rg.name
    resource_suffix     = random_string.suffix.result
    resources = {
      key_vault        = azurerm_key_vault.kv.name
      storage_account  = azurerm_storage_account.sa.name
      ai_services      = azurerm_cognitive_account.ai_services.name
      law_workspace    = azurerm_log_analytics_workspace.law.name
    }
  }
  description = "Information for cleaning up resources"
}