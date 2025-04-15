# Azure AI Infrastructure as Code (Terraform)

This repository contains Terraform templates for deploying core infrastructure required for Azure AI services with security best practices in mind.

## Resources Deployed

This Terraform template deploys the following resources:

1. **Resource Group** - Container for all resources
2. **Key Vault** - For securely storing credentials and secrets
3. **Storage Account** - With a container for AI training data
4. **Azure AI Services** - Multi-service cognitive services resource
5. **Log Analytics Workspace** - For monitoring and logging
6. **Diagnostic Settings** - Comprehensive logging and monitoring configuration

## Security Best Practices

This template implements several security best practices:

- **Secrets Management** - All access keys and connection strings are stored in Azure Key Vault
- **System-Assigned Managed Identity** - Used for AI Services to securely access the Storage Account
- **Role-Based Access Control (RBAC)** - Proper access roles are assigned between resources
- **Network Security** 
  - Configurable IP and subnet access rules
  - Option to disable public network access in production
- **Encryption** 
  - TLS 1.2 minimum for storage accounts
  - Soft delete and purge protection for Key Vault
- **Logging and Monitoring** - Comprehensive diagnostic settings with Log Analytics integration

### Production Considerations

For production deployments, consider these additional security practices:

1. Implement private networking with VNet integration and private endpoints
2. Use more restrictive RBAC roles with least privilege
3. Implement CI/CD pipelines with service principals
4. Add resource locks to prevent accidental deletion
5. Enhance resource tagging for better governance

## Prerequisites

### Tested Versions
- Terraform: v1.5.7
- Azure CLI: v2.71.0

### Required Tools
- **Terraform** (v1.5.0 or later)
  - Ensure Terraform is installed and accessible via command line
  - Recommended: Use `tfenv` or similar version management tool

- **Azure CLI** (v2.50.0 or later)
  - Required for authentication and resource management
  - Ensure you have the latest version installed

- **Additional Dependencies**
  - `jq` (v1.6 or later) - for JSON parsing
  - `bash` (4.0 or later) - for deployment scripts
  - Python 3.8+ (for sentiment analysis example)

### Account Requirements
- Active Azure subscription
- Azure Active Directory account
- Sufficient permissions to:
  - Create resource groups
  - Create Azure AI Services
  - Manage Key Vault
  - Assign RBAC roles

### Authentication
- Log in to Azure CLI before deployment:
  ```bash
  az login
  ```
- Ensure you have the appropriate subscription selected:
  ```bash
  az account set --subscription "Your-Subscription-Name-or-ID"
  ```

### Recommended Local Setup
1. Ensure all required tools are installed
2. Verify tool versions:
   ```bash
   terraform version
   az version
   jq --version
   python3 --version
   ```
3. Configure your Azure CLI and Terraform environment

## Deployment Instructions

1. Clone this repository
2. Navigate to the directory containing the Terraform files
3. Make the deployment script executable: 
   ```bash
   chmod +x deploy.sh
   ```
4. Run the deployment script: 
   ```bash
   ./deploy.sh
   ```

## Configuration Options

You can customize the deployment by modifying variables in `variables.tf`:
- `location` - Azure region for resources
- `environment` - Deployment environment (dev, test, staging, prod)
- `tags` - Additional resource tags
- `allowed_ip_ranges` - IP ranges allowed to access resources
- `secret_expiration_days` - Secret rotation period

## Example Sentiment Analysis Application

A simple sentiment analysis example is included to demonstrate credential retrieval and AI service usage:

### Prerequisites for Example App
1. Install required dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the example application:
   ```bash
   python azure_ai_sentiment_analysis.py
   ```

This example demonstrates:
- Retrieving credentials from Key Vault
- Calling Azure AI service endpoint for sentiment analysis

## Resource Cleanup

Once testing is complete, remove all deployed resources:

```bash
# Automatically detect resource suffix
./cleanup-resources.sh

# Or specify the suffix manually
./cleanup-resources.sh abcd1234

# Force cleanup without confirmation
./cleanup-resources.sh --force
```

## Troubleshooting

If the deployment fails, check:

1. Sufficient permissions in your Azure subscription
2. Location supports all required resource types
3. Resource names are globally unique
4. Review Azure activity logs for detailed error information

### Common Deployment Issues

- 401 Authentication Error: Ensure you're logged into Azure CLI
- Naming Conflicts: Use the cleanup script to remove previous deployments
- Permission Issues: Verify your Azure AD role assignments

## Module Structure

- `main.tf` - Primary Terraform configuration
- `variables.tf` - Input variables and validation
- `outputs.tf` - Deployment output configurations
- `diagnostic_settings.tf` - Logging and monitoring configuration

## Contributing

Contributions to improve security, add features, or fix issues are welcome. Please submit a pull request with detailed descriptions of proposed changes.

## Disclaimer

This is a reference implementation. Always review and adapt to your specific security requirements before production use.