#!/usr/bin/env python3
"""
Azure AI Sentiment Analysis Example
----------------------------------
This script uses AI services deployed via Terraform
and performs sentiment analysis using Azure AI Text Analytics
"""

import os
import json
import sys
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.ai.textanalytics import TextAnalyticsClient
from azure.core.credentials import AzureKeyCredential

def load_terraform_output():
    """
    Load information from Terraform's deployment-outputs.json file
    """
    try:
        # Try loading from terraform output file
        with open('deployment-outputs.json', 'r') as config_file:
            tf_output = json.load(config_file)
            
            # Extract Key Vault and AI Services names from Terraform output
            key_vault_name = tf_output.get('key_vault', {}).get('value', {}).get('name', '')
            ai_services_name = tf_output.get('ai_services', {}).get('value', {}).get('name', '')
            
            config = {
                'KEY_VAULT_NAME': key_vault_name,
                'AI_SERVICES_NAME': ai_services_name
            }
            
            print(f"📋 Loaded configuration from Terraform output:")
            print(f"   Key Vault: {key_vault_name}")
            print(f"   AI Service: {ai_services_name}")
            
            # Validate configuration
            if not config['KEY_VAULT_NAME'] or not config['AI_SERVICES_NAME']:
                raise ValueError("Missing required configuration values")
                
            return config
            
    except (FileNotFoundError, json.JSONDecodeError, ValueError) as e:
        print(f"❌ Error loading Terraform output: {str(e)}")
        
        # Try loading from deployment_config.json instead
        try:
            with open('deployment_config.json', 'r') as config_file:
                config = json.load(config_file)
                print(f"📋 Loaded configuration from deployment_config.json:")
                print(f"   Key Vault: {config.get('KEY_VAULT_NAME', '')}")
                print(f"   AI Service: {config.get('AI_SERVICES_NAME', '')}")
                
                # Validate configuration
                if not config.get('KEY_VAULT_NAME') or not config.get('AI_SERVICES_NAME'):
                    raise ValueError("Missing required configuration values")
                    
                return config
        except (FileNotFoundError, json.JSONDecodeError, ValueError) as e2:
            print(f"❌ Error loading deployment_config.json: {str(e2)}")
        
        # Fallback to manual input
        print("\n⌨️ Please provide the required information manually:")
        key_vault_name = input("Key Vault Name: ")
        ai_services_name = input("AI Services Name: ")
        
        config = {
            'KEY_VAULT_NAME': key_vault_name,
            'AI_SERVICES_NAME': ai_services_name
        }
        
        if not config['KEY_VAULT_NAME'] or not config['AI_SERVICES_NAME']:
            print("❌ Required configuration values not provided")
            sys.exit(1)
            
        return config

def get_credentials_from_keyvault(config):
    """
    Retrieves AI service credentials from Azure Key Vault using DefaultAzureCredential
    """
    try:
        print(f"🔐 Attempting to connect to Key Vault: {config['KEY_VAULT_NAME']}")
        
        # Create a credential object using DefaultAzureCredential
        credential = DefaultAzureCredential()
        
        # Create a secret client to access the Key Vault
        key_vault_uri = f"https://{config['KEY_VAULT_NAME']}.vault.azure.net/"
        secret_client = SecretClient(vault_url=key_vault_uri, credential=credential)
        
        # Try to get the secret names from the configuration
        ai_key_name = "ai-services-key"  # Based on the Terraform configuration
        ai_endpoint_name = "ai-services-endpoint"  # Based on the Terraform configuration
        
        print(f"🔑 Retrieving secrets: {ai_key_name}, {ai_endpoint_name}")
        
        # Retrieve the AI service key and endpoint from Key Vault
        ai_key = secret_client.get_secret(ai_key_name).value
        ai_endpoint = secret_client.get_secret(ai_endpoint_name).value
        
        print(f"✅ Successfully retrieved credentials from Key Vault")
        print(f"   Endpoint: {ai_endpoint}")
        
        return ai_key, ai_endpoint
    except Exception as e:
        print(f"❌ Error retrieving credentials from Key Vault: {str(e)}")
        print("\n🔍 Troubleshooting tips:")
        print("   1. Verify that you are logged in with Azure CLI: az login")
        print("   2. Check if you have proper access to the Key Vault")
        print("   3. Verify that the secret names match the ones in Key Vault")
        sys.exit(1)

def analyze_sentiment(key, endpoint, text):
    """
    Performs sentiment analysis on the provided text using Azure AI Text Analytics
    """
    try:
        # Create a client for Text Analytics with the retrieved credentials
        text_analytics_client = TextAnalyticsClient(
            endpoint=endpoint,
            credential=AzureKeyCredential(key)
        )
        
        # Analyze sentiment of the provided text
        documents = [text]
        response = text_analytics_client.analyze_sentiment(documents)
        
        # Process the response
        for result in response:
            if result.is_error:
                print(f"❌ Error: {result.id}, {result.error}")
            else:
                print(f"\n📝 Text: \"{result.sentences[0].text}\"")
                print(f"🔍 Sentiment: {result.sentiment}")
                print(f"📊 Confidence scores:")
                print(f"   Positive: {result.confidence_scores.positive:.2f}")
                print(f"   Neutral:  {result.confidence_scores.neutral:.2f}")
                print(f"   Negative: {result.confidence_scores.negative:.2f}")
                
    except Exception as e:
        print(f"❌ Error analyzing sentiment: {str(e)}")
        # Print full traceback for more detailed error information
        import traceback
        traceback.print_exc()
        sys.exit(1)

def main():
    """
    Main execution function for sentiment analysis
    """
    print("=== Azure AI Services Sentiment Analysis ===")
    print("🔍 Loading configuration from Terraform output...")
    config = load_terraform_output()
    
    print("\n🔐 Retrieving credentials from Azure Key Vault...")
    key, endpoint = get_credentials_from_keyvault(config)
    
    # Let the user enter text for analysis
    print("\n⌨️ Enter text for sentiment analysis (or press Enter for default):")
    user_text = input("> ")
    text_to_analyze = user_text if user_text else "Infrastructure as Code is the best approach for cloud deployments"
    
    print("\n📊 Performing sentiment analysis...")
    analyze_sentiment(key, endpoint, text_to_analyze)

if __name__ == "__main__":
    main()
    