# README

## Why This Matters
Microsoft Azure AI training offers great insights into their service offerings, but the labs cut corners that present several security vulnerabilities. For example, learners are often directed to store secrets in plain text with code—a risky move that can lead to leaks, as the AI-102 curriculum’s focus on API key rotation suggests. We’re here to highlight secure, empowering alternatives for safeguarding credentials.

### Risks of Secrets Mishandling
Code repositories—whether in the cloud, on laptops, or in backups—are widely accessible. Storing secrets alongside code, even if later overwritten (see [TruffleHog](https://github.com/trufflesecurity/trufflehog)), leaves them exposed. Attackers can exploit these gaps to infiltrate systems, drain resources, or steal sensitive data.

#### Anti-pattern Examples
- **`.env` File**:  
  - **Instructions**: [mslearn-openai - 01-app-develop.md](https://github.com/MicrosoftLearning/mslearn-openai/blob/main/Instructions/Exercises/01-app-develop.md)  
  - **Repo**: [mslearn-openai/.env#L2](https://github.com/MicrosoftLearning/mslearn-openai/blob/main/Labfiles/01-app-develop/Python/.env#L2)  
- **`.json` File**:  
  - **Instructions**: [mslearn-knowledge-mining - 01-azure-search.md](https://github.com/MicrosoftLearning/mslearn-knowledge-mining/blob/main/Instructions/Exercises/01-azure-search.md)  
  - **Repo**: [mslearn-knowledge-mining/skillset.json#L7](https://github.com/MicrosoftLearning/mslearn-knowledge-mining/blob/main/Labfiles/01-azure-search/modify-search/skillset.json#L7)

## A Better Way: Vaults
Per the [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html), vaults are the gold standard for secrets handling. In production, tools like [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) for Kubernetes or [HashiCorp Vault](https://www.vaultproject.io/) excel at handling secrets in microservices. While these may be out of reach for local development and testing, additional effective options are available.

**Bonus**: Using vaults programmatically also prevents accidental leaks—like pasting secrets into terminals for environment variables or curl headers—which can linger in command history or other logs, risking exposure.

### Example 1: Azure Key Vault
[Azure Key Vault](https://learn.microsoft.com/en-us/azure/ai-services/use-key-vault) provides a native, secure home for secrets, keys, and certificates. Assign the [Key Vault Secrets User](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#key-vault-secrets-user) IAM role to a developer’s Azure AD account, and they can fetch secrets safely—no hardcoding needed.

**Pro Tip**: Tighten security by limiting Key Vault access to a private network (e.g. via VPN) to shrink its attack surface.

See our example ([`./azure_vault_auth.py`](./azure_vault_auth.py)), which pulls Cognitive Services credentials from Key Vault to detect the language of user input, leveraging the [Azure Identity library](https://learn.microsoft.com/en-us/python/api/azure-identity/azure.identity?view=azure-python) and [Azure Key Vault Secrets client](https://learn.microsoft.com/en-us/python/api/azure-keyvault-secrets/azure.keyvault.secrets.secretclient?view=azure-python).

#### Prerequisites
- Assign the "Key Vault Secrets User" role to the developers Azure AD account ([Azure RBAC Guide](https://learn.microsoft.com/en-us/azure/key-vault/general/rbac-guide)) to allow scripts run in their user context to read secrets from the vault.

### Example 2: 1Password Vault
Hailing from Ontario, Canada, with robust privacy laws, 1Password builds trust by sharing penetration test reports ([1Password Security Assessments](https://support.1password.com/security-assessments/)). Paired with its [CLI tool](https://developer.1password.com/docs/cli/get-started/), this affordable service lets you securely retrieve secrets in scripts and apps.

Explore our example ([`./1p_vault_auth.py`](./1p_vault_auth.py)), which fetches Cognitive Services credentials for sentiment analysis of text input.

#### Prerequisites
- A 1Password account
- [Set up the 1P CLI tool](https://developer.1password.com/docs/cli/get-started/)