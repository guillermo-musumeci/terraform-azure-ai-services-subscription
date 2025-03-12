###########################
## Azure Provider - Main ##
###########################

## Define Terraform and Azure providers ##
terraform {
  required_version = ">= 1.11"
  
  required_providers {
    azurerm = {
      version               = "~>4.2"
      source                = "hashicorp/azurerm"
      configuration_aliases = [ azurerm, azurerm.customer, azurerm.core ]
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>3.1"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~>2.2"
    }
  }
}

## Configure the Azure provider for Customer ##
provider "azurerm" {
  subscription_id = var.azure-subscription-customer-id
  client_id       = var.azure-client-id
  client_secret   = var.azure-client-secret
  tenant_id       = var.azure-tenant-id
  features {
    subscription {
      prevent_cancellation_on_destroy = false
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}

## Configure the Azure provider for Customer ##
provider "azurerm" {
  alias           = "customer"
  subscription_id = var.azure-subscription-customer-id
  client_id       = var.azure-client-id
  client_secret   = var.azure-client-secret
  tenant_id       = var.azure-tenant-id
  features {
    subscription {
      prevent_cancellation_on_destroy = false
    }
    cognitive_account {
      purge_soft_delete_on_destroy = true
    }
  }
}

## Configure the Azure provider for Core ##
provider "azurerm" {
  alias           = "core"
  subscription_id = var.azure-subscription-core-id
  client_id       = var.azure-client-id
  client_secret   = var.azure-client-secret
  tenant_id       = var.azure-tenant-id
  features {}
}
