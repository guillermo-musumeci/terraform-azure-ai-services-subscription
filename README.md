# Deploying an Azure AI Services using Terraform
[![Terraform](https://img.shields.io/badge/terraform-v1.11+-blue.svg)](https://www.terraform.io/downloads.html)

## Overview

Deploy multiple Azure AI services using Terraform.

## Code Creates

List of Azure resources created with Terraform:

- Resource Group
- VNET
- Subnet
- Subnet for Private Endpoint
- Subnet for Application Services (WebApp/Function)
- Azure OpenAI with Private Endpoint
- Azure AI Search with Private Endpoint
- Azure Storage Account with Private Endpoint for Blob, DFS, and Table
- Log Analytics and Application Insights

Azure AI Foundry resources:

- Azure Storage Account for Azure AI Foundry Hub
- Azure Key Vault for Azure AI Foundry Hub
- Azure AI Foundry Hub with Private Endpoint
- Azure AI Foundry Project
- Azure OpenAI Service Connection
- Azure AI Search Service Connection
- Azure Storage Account Service Connection

**Note:** All Private DNS Zones references are created in a central Core subscription and can be incorporated in this repo if only one subscription is used.
Core Subscription Repo --> https://github.com/guillermo-musumeci/terraform-azure-ai-core-subscription

## References

- How to Deploy Azure AI Search with a Private Endpoint using Terraform --> https://medium.com/@gmusumeci/how-to-deploy-azure-ai-search-with-a-private-endpoint-using-terraform-3b63c8b84f41
- How to Deploy Azure OpenAI with Private Endpoint and ChatGPT using Terraform --> https://medium.com/@gmusumeci/how-to-deploy-azure-openai-with-private-endpoint-and-chatgpt-using-terraform-253cfd1513aa
- Using Private Endpoint in Azure Storage Account with Terraform --> https://medium.com/@gmusumeci/using-private-endpoint-in-azure-storage-account-with-terraform-49b4734ada34
