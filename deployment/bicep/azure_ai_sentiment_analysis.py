#!/usr/bin/env python3
"""
Azure AI Sentiment Analysis Example
----------------------------------
This script dynamically retrieves Azure resource credentials
and performs sentiment analysis using Azure AI Text Analytics
"""

import os
import json
import sys
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.ai.textanalytics import TextAnalyticsClient
from azure.core.credentials import AzureKeyCredential

def load_deployment_config():
    """
    Load deployment configuration from JSON file or environment variables
    """
    try:
        # Try loading from file first
        with open('deployment_config.json', 'r') as config_file:
            return json.load(config_file)
    except FileNotFoundError:
        # Fallback to environment variables
        config = {
            'KEY_VAULT_NAME': os.environ.get('KEY_VAULT_NAME', ''),
            'AI_SERVICES_NAME': os.environ.get('AI_SERVICES_NAME', '')
        }
        
        # Validate configuration
        if not config['KEY_VAULT_NAME'] or not config['AI_SERVICES_NAME']:
            print("❌ Unable to find deployment configuration")
            print("Please ensure deployment_config.json exists or environment variables are set")
            sys.exit(1)
        
        return config

def get_credentials_from_keyvault(config):
    """
    Retrieves AI service credentials from Azure Key Vault using DefaultAzureCredential
    """
    try:
        # Create a credential object using DefaultAzureCredential
        credential = DefaultAzureCredential()
        
        # Create a secret client to access the Key Vault
        key_vault_uri = f"https://{config['KEY_VAULT_NAME']}.vault.azure.net/"
        secret_client = SecretClient(vault_url=key_vault_uri, credential=credential)
        
        # Retrieve the AI service key and endpoint from Key Vault
        ai_key = secret_client.get_secret(f"{config['AI_SERVICES_NAME']}-key").value
        ai_endpoint = secret_client.get_secret(f"{config['AI_SERVICES_NAME']}-endpoint").value
        
        print(f"✅ Successfully retrieved credentials from Key Vault")
        print(f"   Vault: {config['KEY_VAULT_NAME']}")
        print(f"   AI Service: {config['AI_SERVICES_NAME']}")
        print(f"   Endpoint: {ai_endpoint}")  # Add this line to print the endpoint
        
        return ai_key, ai_endpoint
    except Exception as e:
        print(f"❌ Error retrieving credentials from Key Vault: {str(e)}")
        sys.exit(1)

def analyze_sentiment(key, endpoint, text):
    """
    Performs sentiment analysis on the provided text using Azure AI Text Analytics
    """
    try:
        # Diagnostic print of key and endpoint
        print(f"🔍 Diagnostic Info:")
        print(f"   Key Length: {len(key)}")
        print(f"   Endpoint: {endpoint}")

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
                print(f"📝 Text: \"{result.sentences[0].text}\"")
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
    print("🔑 Loading deployment configuration...")
    config = load_deployment_config()
    
    print("🔐 Retrieving credentials from Azure Key Vault...")
    key, endpoint = get_credentials_from_keyvault(config)
    
    print("\n📊 Performing sentiment analysis...")
    text_to_analyze = "Just say NO to click-ops deployments"
    analyze_sentiment(key, endpoint, text_to_analyze)

if __name__ == "__main__":
    main()