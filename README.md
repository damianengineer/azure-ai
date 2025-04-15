# README

# Azure AI-102 Certification Course Review

As expected, this was a general knowledge survey course that focused more on administration than engineering skill building. However, I found their training exercises valuable for introducing me to various endpoints and capabilities with potential enterprise applications, such as:

## Image Analysis
* Image captioning, object detection, and content moderation with out-of-box accuracy ([Documentation](https://learn.microsoft.com/en-us/azure/ai-services/computer-vision/))
* Specialized classification with minimal training data for domain-specific visual detection ([Custom Vision Documentation](https://learn.microsoft.com/en-us/azure/ai-services/custom-vision-service/))

## Document Intelligence
* Process invoices, receipts, IDs, and W-2s out-of-box, reducing processing time ([Documentation](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/))
* Train on company-specific documents to extract structured data from proprietary forms ([Custom Models Documentation](https://learn.microsoft.com/en-us/azure/ai-services/document-intelligence/))

## NLP
* Sentiment analysis, NER, PII detection, and key phrase extraction enabling contact center analytics ([Text Analytics Documentation](https://learn.microsoft.com/en-us/azure/ai-services/language-service/))
* Intent recognition for chatbots with multi-turn conversation management capabilities ([Conversational Language Documentation](https://learn.microsoft.com/en-us/azure/ai-services/language-service/conversational-language-understanding/overview))

## Knowledge Mining
* Full-text search, faceting, and cognitive enrichment providing unified enterprise content search ([AI Search Documentation](https://learn.microsoft.com/en-us/azure/search/))
* Context-aware relevance scoring improving search quality over keyword-only approaches ([Semantic Rankings Documentation](https://learn.microsoft.com/en-us/azure/search/semantic-search-overview))

## Azure OpenAI
* Enterprise-grade GPT with content safety filtering and system instructions for guardrails ([Chat Completions Documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/))
* Vector representations for semantic similarity powering RAG applications with proprietary data ([Embeddings Documentation](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/understand-embeddings))

## Enterprise AI
* Single authentication system across all services using AAD token auth ([Authentication Documentation](https://learn.microsoft.com/en-us/dotnet/api/azure.identity.defaultazurecredential))
* Vision, Language, and Doc Intelligence supporting edge deployment for air-gapped operations ([Containerization Documentation](https://learn.microsoft.com/en-us/azure/ai-services/cognitive-services-container-support))
* Certified compliance (SOC 1/2, HIPAA, ISO 27001, GDPR) covering enterprise regulatory requirements #AIGovernance ([Compliance Documentation](https://learn.microsoft.com/en-us/azure/compliance/))

# Examples of improvements that could be incorporated into the course 
- [Secrets Handling](./secrets_handling/README.md)
