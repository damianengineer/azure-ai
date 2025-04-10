#!/usr/bin/env python3

import json
import logging
import subprocess
from typing import Optional, Union, List, Dict
from azure.ai.textanalytics import TextAnalyticsClient
from azure.core.credentials import AzureKeyCredential

# Global parameters for easy modification (for demo purposes)
LOG_LEVEL = logging.INFO  # Set to logging.DEBUG to see secret values
VAULT_NAME = "demo"  # Vault name in 1Password
ITEM_NAME = "CognitiveServices"  # Item name in 1Password
API_KEY_FIELD = "api_key"  # Field for Cognitive Services API key
ENDPOINT_FIELD = "endpoint"  # Field for Cognitive Services endpoint

# Configure logging with global log level
logging.basicConfig(
    level=LOG_LEVEL,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger(__name__)

class OnePasswordCLIClient:
    """A client to interact with 1Password CLI for secret retrieval."""

    def __init__(self, cli_executable: str = "op"):
        """Initialize the client with the CLI executable path."""
        self.cli_executable = cli_executable

    def get_secret(
        self, vault: str, item: str, field: str
    ) -> Optional[str]:
        """
        Retrieve a secret from a 1Password vault using the CLI.

        Args:
            vault: Name of the vault containing the item.
            item: Name or ID of the item (secret).
            field: Name of the field containing the secret value.

        Returns:
            The secret value as a string, or None if retrieval fails.
        """
        command = [
            self.cli_executable, "item", "get", item,
            "--vault", vault,
            "--fields", field,
            "--format", "json"
        ]

        try:
            logger.debug("Executing command: %s", " ".join(command))
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=True,
                timeout=10
            )

            output: Union[Dict, List[Dict]] = json.loads(result.stdout)
            logger.debug("Raw CLI output: %s", output)

            if isinstance(output, dict):
                if output.get("label") == field:
                    return output.get("value")
                logger.warning("Field '%s' not found in single-field output", field)
                return None
            elif isinstance(output, list):
                for field_data in output:
                    if field_data.get("label") == field:
                        return field_data.get("value")
                logger.warning("Field '%s' not found in multi-field output", field)
                return None
            else:
                logger.error("Unexpected output type: %s", type(output))
                return None

        except subprocess.CalledProcessError as e:
            logger.error("CLI command failed: %s", e.stderr)
            return None
        except subprocess.TimeoutExpired as e:
            logger.error("CLI command timed out: %s", e.stderr)
            return None
        except json.JSONDecodeError as e:
            logger.error("Failed to parse CLI output: %s", e)
            return None
        except Exception as e:
            logger.exception("Unexpected error retrieving secret: %s", e)
            return None

def get_cognitive_services_client() -> Optional[TextAnalyticsClient]:
    """Authenticate to Azure Cognitive Services using secrets from 1Password."""
    client = OnePasswordCLIClient()

    # Retrieve API key and endpoint from 1Password
    api_key = client.get_secret(VAULT_NAME, ITEM_NAME, API_KEY_FIELD)
    endpoint = client.get_secret(VAULT_NAME, ITEM_NAME, ENDPOINT_FIELD)

    if not api_key or not endpoint:
        logger.error("Failed to retrieve Cognitive Services credentials")
        return None

    # Log secrets conditionally based on log level
    if logger.isEnabledFor(logging.DEBUG):
        logger.debug("API Key: %s", api_key)
        logger.debug("Endpoint: %s", endpoint)
    else:
        logger.debug("API Key: [REDACTED]")
        logger.debug("Endpoint: [REDACTED]")

    try:
        # Authenticate to Cognitive Services
        credential = AzureKeyCredential(api_key)
        text_analytics_client = TextAnalyticsClient(endpoint=endpoint, credential=credential)
        logger.info("Successfully authenticated to Cognitive Services")
        return text_analytics_client
    except Exception as e:
        logger.error("Failed to authenticate to Cognitive Services: %s", e)
        return None

def analyze_text(client: TextAnalyticsClient, text: str):
    """Example function to analyze text using Cognitive Services."""
    try:
        # Log the sample text before analysis
        logger.info("Sample text for analysis: %s", text)
        result = client.analyze_sentiment(documents=[text])[0]
        logger.info("Sentiment analysis result: %s", result.sentiment)
    except Exception as e:
        logger.error("Text analysis failed: %s", e)

def main():
    """Main function to demonstrate secure secrets handling."""
    client = get_cognitive_services_client()
    if client:
        # Example usage of the authenticated client
        sample_text = "The referenced Microsoft example includes a vulnerability in secrets handling. DO NOT store plain text secrets with code!!!"
        analyze_text(client, sample_text)
    else:
        logger.error("Cannot proceed without a valid Cognitive Services client")

if __name__ == "__main__":
    main()