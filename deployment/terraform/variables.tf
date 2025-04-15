variable "location" {
  type        = string
  description = "The Azure region where resources will be created"
  default     = "eastus"
  validation {
    condition     = contains(["eastus", "eastus2", "westus2", "westeurope", "northeurope"], var.location)
    error_message = "The location must be one of the supported regions: eastus, eastus2, westus2, westeurope, northeurope."
  }
}

variable "environment" {
  type        = string
  description = "The environment name (dev, test, staging, prod)"
  default     = "dev"
  validation {
    condition     = contains(["dev", "test", "staging", "prod"], var.environment)
    error_message = "The environment must be one of: dev, test, staging, prod."
  }
}

variable "environment_prefix" {
  type        = string
  description = "Prefix to use for all resource names (typically aligned with environment)"
  default     = "dev"
  validation {
    condition     = length(var.environment_prefix) <= 5
    error_message = "The environment prefix cannot be longer than 5 characters."
  }
}

variable "project_name" {
  type        = string
  description = "The name of the project"
  default     = "AzureAIDeployment"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources"
  default = {
    Owner        = "AI Team"
    CostCenter   = "12345"
  }
}

variable "allowed_ip_ranges" {
  type        = list(string)
  description = "List of IP ranges to allow access to resources"
  default     = []
}

variable "allowed_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to allow access to resources"
  default     = []
}

variable "secret_expiration_days" {
  type        = number
  description = "Number of days until secrets expire (for rotation)"
  default     = 90
  validation {
    condition     = var.secret_expiration_days >= 30 && var.secret_expiration_days <= 365
    error_message = "Secret expiration must be between 30 and 365 days."
  }
}
