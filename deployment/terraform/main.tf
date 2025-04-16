terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }
  
  # Uncomment to use remote backend
  # backend "azurerm" {
  #   resource_group_name  = "tfstate"
  #   storage_account_name = "tfstate<unique_suffix>"
  #   container_name       = "tfstate"
  #   key                  = "ai-services.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
  
  # Skip provider registration since we don't have permissions
  skip_provider_registration = true
}

# Get current Azure configuration
data "azurerm_client_config" "current" {}

# Define resource naming conventions using locals
locals {
  # Base prefix for all resources
  prefix = var.environment_prefix
  
  # Generate a random suffix for all resources
  suffix = random_string.suffix.result
  
  # Common tags for all resources
  common_tags = merge(var.tags, {
    Environment     = var.environment
    Project         = var.project_name
    ManagedBy       = "Terraform"
    DeploymentDate  = formatdate("YYYY-MM-DD", timestamp())
  })
}

# Generate a random suffix for all resources
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
  min_lower = 1
  min_numeric = 1
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix}-rg-aiservices-${local.suffix}"
  location = var.location
  tags     = local.common_tags
  
  lifecycle {
    prevent_destroy = false # Set to true in production
    # Ignore changes to tags
    ignore_changes = [
      tags,
    ]
  }
}

# Create a Key Vault with enhanced security
resource "azurerm_key_vault" "kv" {
  name                        = "${local.prefix}kv${local.suffix}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = var.environment == "prod" ? 90 : 7
  purge_protection_enabled    = var.environment == "prod" ? true : false
  sku_name                    = "standard"
  tags                        = local.common_tags
  enable_rbac_authorization   = false # Set to true if using RBAC instead of access policies

  # Configure network access control for enhanced security
  network_acls {
    default_action             = var.environment == "prod" ? "Deny" : "Allow"
    bypass                     = "AzureServices"
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  lifecycle {
    prevent_destroy = false # Set to true in production
    # Ignore access policies managed separately
    ignore_changes = [
      access_policy,
    ]
  }
}

# Grant the current user access to the Key Vault (minimum required permissions)
resource "azurerm_key_vault_access_policy" "user" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Recover", "Purge"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Backup", "Restore", "Recover", "Purge"
  ]

  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Recover", "Purge"
  ]
}

# Create a Storage Account with enhanced security
resource "azurerm_storage_account" "sa" {
  name                            = "${local.prefix}sa${local.suffix}"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = var.environment == "prod" ? "GRS" : "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true # Hierarchical namespace for Data Lake Gen2
  min_tls_version                 = "TLS1_2"
  enable_https_traffic_only       = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true
  
  blob_properties {
    # Note: versioning_enabled is removed as it's incompatible with HNS
    last_access_time_enabled = true
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }
  
  tags = local.common_tags

  # Add network rules for enhanced security
  network_rules {
    default_action             = var.environment == "prod" ? "Deny" : "Allow"
    bypass                     = ["AzureServices"]
    ip_rules                   = var.allowed_ip_ranges
    virtual_network_subnet_ids = var.allowed_subnet_ids
  }

  lifecycle {
    prevent_destroy = false # Set to true in production
    # Ignore changes to blob_properties to prevent conflicts
    ignore_changes = [
      blob_properties,
    ]
  }
}

# Create a container in the Storage Account for AI training data
resource "azurerm_storage_container" "container" {
  name                  = "aitrainingdata"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
  
  # Ensure container is created only after storage account is fully provisioned
  depends_on = [azurerm_storage_account.sa]
}

# Create Log Analytics workspace for monitoring
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${local.prefix}-law-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = var.environment == "prod" ? 90 : 30
  tags                = local.common_tags
}

# Create Azure AI Services (Cognitive Services) with a system-assigned identity
resource "azurerm_cognitive_account" "ai_services" {
  name                = "${local.prefix}-ai-${local.suffix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "CognitiveServices"
  sku_name            = var.environment == "prod" ? "S1" : "S0"
  tags                = local.common_tags
  custom_subdomain_name = "${local.prefix}-ai-${local.suffix}" # Enables private endpoints
  public_network_access_enabled = var.environment == "prod" ? false : true

  identity {
    type = "SystemAssigned"
  }
  
  # Network rules for enhanced security
  network_acls {
    default_action = var.environment == "prod" ? "Deny" : "Allow"
    ip_rules       = var.allowed_ip_ranges
  }
  
  depends_on = [
    azurerm_log_analytics_workspace.law
  ]
}

# Store the AI Services key in Key Vault
resource "azurerm_key_vault_secret" "ai_key" {
  name         = "ai-services-key"
  value        = azurerm_cognitive_account.ai_services.primary_access_key
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "text/plain"
  
  # Add expiration date for key rotation policy
  expiration_date = timeadd(timestamp(), "${var.secret_expiration_days * 24}h")
  
  depends_on   = [azurerm_key_vault_access_policy.user]
}

# Store the AI Services endpoint in Key Vault
resource "azurerm_key_vault_secret" "ai_endpoint" {
  name         = "ai-services-endpoint"
  value        = azurerm_cognitive_account.ai_services.endpoint
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "text/plain"
  
  # Add expiration date for key rotation policy
  expiration_date = timeadd(timestamp(), "${var.secret_expiration_days * 24}h")
  
  depends_on   = [azurerm_key_vault_access_policy.user]
}

# Store the Storage Account connection string in Key Vault
resource "azurerm_key_vault_secret" "storage_connection" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.sa.primary_connection_string
  key_vault_id = azurerm_key_vault.kv.id
  content_type = "text/plain"
  
  # Add expiration date for key rotation policy
  expiration_date = timeadd(timestamp(), "${var.secret_expiration_days * 24}h")
  
  depends_on   = [azurerm_key_vault_access_policy.user]
}

# Assign the Azure AI Services system-assigned identity to the Storage Blob Data Reader role
resource "azurerm_role_assignment" "ai_to_storage" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_cognitive_account.ai_services.identity[0].principal_id
  description          = "Allow AI Services to read blob data for training models"
  
  # Add depends_on to ensure proper creation order
  depends_on = [
    azurerm_cognitive_account.ai_services,
    azurerm_storage_account.sa
  ]
}
