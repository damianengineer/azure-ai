#!/usr/bin/env python3
"""
Azure AI Sentiment Analysis Example
----------------------------------
This script shows how to:
1. Authenticate to Azure Key Vault using DefaultAzureCredential
2. Retrieve AI service credentials from Key Vault
3. Use the Text Analytics API to perform sentiment analysis
"""

import os
import sys
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.ai.textanalytics import TextAnalyticsClient
from azure.core.credentials import AzureKeyCredential

# Output resource names from Bicep deployment
KEY_VAULT_NAME = "aiproject-dev-kv-7dtojm"  # Replace with your Key Vault name from deployment output
AI_SERVICE_NAME = "aiproject-dev-ai"       # Replace with your AI service name from deployment output

def get_credentials_from_keyvault():
    """
    Retrieves AI service credentials from Azure Key Vault using DefaultAzureCredential
    """
    try:
        # Create a credential object using DefaultAzureCredential
        credential = DefaultAzureCredential()
        
        # Create a secret client to access the Key Vault
        key_vault_uri = f"https://{KEY_VAULT_NAME}.vault.azure.net/"
        secret_client = SecretClient(vault_url=key_vault_uri, credential=credential)
        
        # Retrieve the AI service key and endpoint from Key Vault
        ai_key = secret_client.get_secret(f"{AI_SERVICE_NAME}-key").value
        ai_endpoint = secret_client.get_secret(f"{AI_SERVICE_NAME}-endpoint").value
        
        print(f"✅ Successfully retrieved credentials from Key Vault")
        return ai_key, ai_endpoint
    except Exception as e:
        print(f"❌ Error retrieving credentials from Key Vault: {str(e)}")
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
                print(f"📝 Text: \"{result.sentences[0].text}\"")
                print(f"🔍 Sentiment: {result.sentiment}")
                print(f"📊 Confidence scores:")
                print(f"   Positive: {result.confidence_scores.positive:.2f}")
                print(f"   Neutral:  {result.confidence_scores.neutral:.2f}")
                print(f"   Negative: {result.confidence_scores.negative:.2f}")
                
    except Exception as e:
        print(f"❌ Error analyzing sentiment: {str(e)}")
        sys.exit(1)

def main():
    print("🔑 Retrieving credentials from Azure Key Vault...")
    key, endpoint = get_credentials_from_keyvault()
    
    print("\n📊 Performing sentiment analysis...")
    text_to_analyze = "Just say NO to click-ops deployments"
    analyze_sentiment(key, endpoint, text_to_analyze)

if __name__ == "__main__":
    main()