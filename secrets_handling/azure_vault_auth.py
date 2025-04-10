import argparse
import logging
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.core.credentials import AzureKeyCredential
from azure.ai.textanalytics import TextAnalyticsClient

def setup_logging():
    """Configure logging for the application."""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

def get_secret_from_vault(vault_url, secret_name):
    """
    Retrieve a secret from Azure Key Vault using DefaultAzureCredential.
    
    Args:
        vault_url (str): The URL of the Azure Key Vault.
        secret_name (str): The name of the secret to retrieve.
    
    Returns:
        str: The value of the retrieved secret.
    
    Raises:
        Exception: If the secret retrieval fails.
    """
    try:
        credential = DefaultAzureCredential()
        secret_client = SecretClient(vault_url=vault_url, credential=credential)
        secret = secret_client.get_secret(secret_name).value
        logging.info(f"Successfully retrieved secret: {secret_name}")
        return secret
    except Exception as ex:
        logging.error(f"Failed to retrieve secret '{secret_name}' from Key Vault: {ex}")
        raise

def detect_language(text, endpoint, key):
    """
    Detect the language of the input text using Azure Text Analytics.
    
    Args:
        text (str): The text to analyze.
        endpoint (str): The endpoint URL of the Text Analytics service.
        key (str): The API key for the Text Analytics service.
    
    Returns:
        str: The name of the detected primary language.
    
    Raises:
        Exception: If language detection fails.
    """
    try:
        credential = AzureKeyCredential(key)
        client = TextAnalyticsClient(endpoint=endpoint, credential=credential)
        response = client.detect_language(documents=[text])[0]
        language = response.primary_language.name
        logging.info(f"Detected language: {language}")
        return language
    except Exception as ex:
        logging.error(f"Failed to detect language: {ex}")
        raise

def main():
    setup_logging()
    parser = argparse.ArgumentParser(description='Process text using Azure AI services.')
    parser.add_argument('--key-vault-url', required=True, help='The URL of the Azure Key Vault.')
    args = parser.parse_args()

    try:
        ai_endpoint = get_secret_from_vault(args.key_vault_url, "AI-SERVICE-ENDPOINT")
        ai_key = get_secret_from_vault(args.key_vault_url, "AI-SERVICE-KEY")

        while True:
            user_text = input('\nEnter some text ("quit" to stop):\n')
            if user_text.lower() == "quit":
                logging.info("Exiting application.")
                break
            language = detect_language(user_text, ai_endpoint, ai_key)
            print('Detected Language:', language)

    except Exception as ex:
        logging.critical(f"Application terminated with an error: {ex}")

if __name__ == "__main__":
    main()