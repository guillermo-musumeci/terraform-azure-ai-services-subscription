##################################
## Azure AI Foundry - Resources ##
##################################

## Retrieve the Azure Client Config ##
data "azurerm_client_config" "current" { }

## Generate a Random String ##
resource "random_string" "foundry" {  
  length  = 3  
  special = false  
  upper   = false  
} 

## Create a Storage Account for Azure AI Foundry ##
resource "azurerm_storage_account" "foundry" {
  name                            = "${lower(var.app_name)}${var.environment}hubst"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = false

  tags = var.tags
}

## Create a Key Vault for Azure AI Foundry ##
resource "azurerm_key_vault" "foundry" {
  name                       = "${lower(var.app_name)}${var.environment}hubkv"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  tags = var.tags
}

## Create Azure AI Hub ##
resource "azapi_resource" "hub" {
  type      = "Microsoft.MachineLearningServices/workspaces@2024-04-01-preview"
  name      = "${lower(var.app_name)}-${var.environment}-hub"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      description    = "${lower(var.app_name)}-${var.environment}-hub"
      friendlyName   = "${lower(var.app_name)}-${var.environment}-hub"
      storageAccount = azurerm_storage_account.foundry.id
      keyVault       = azurerm_key_vault.foundry.id
    }
    kind = "Hub"
  }
  response_export_values = ["properties"]

  depends_on= [ azurerm_storage_account.foundry, azurerm_key_vault.foundry ]
}

## Give access to Azure Hub to users ##
resource "azurerm_role_assignment" "ai_hub_users" {
  for_each             = toset(var.genai_user_ids)
  principal_id         = each.value
  role_definition_name = "Owner"
  scope                = azapi_resource.hub.id
}

## Create Azure AI Project ##
resource "azapi_resource" "project" {
  type      = "Microsoft.MachineLearningServices/workspaces@2024-04-01-preview"
  name      = "${lower(var.app_name)}-${var.environment}-project"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  identity {
    type = "SystemAssigned"
  }

  body = {
    properties = {
      description   = "${lower(var.app_name)}-${var.environment}-project"
      friendlyName  = "${lower(var.app_name)}-${var.environment}-project"
      hubResourceId = azapi_resource.hub.id
    }
    kind = "project"
  }

  depends_on= [ azurerm_resource_group.rg, azapi_resource.hub ]
}

## Create Private DNS Zone Virtual Network Link for Azure Machine Learning ##
resource "azurerm_private_dns_zone_virtual_network_link" "azureml" {
  provider = azurerm.core

  name                  = "${azapi_resource.hub.name}-vnet-link"
  resource_group_name   = data.azurerm_private_dns_zone.azureml.resource_group_name
  private_dns_zone_name = data.azurerm_private_dns_zone.azureml.name
  virtual_network_id    = azurerm_virtual_network.vnet.id

  depends_on = [ 
    azapi_resource.hub,
    azurerm_resource_group.rg, 
    azurerm_virtual_network.vnet
  ]
}

## Create the Private Endpoint for Azure Machine Learning ##
resource "azurerm_private_endpoint" "azureml" {
  name                = "${azapi_resource.hub.name}-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet-pe.id

  private_service_connection {
    name                           = "${azapi_resource.hub.name}-pe-psc"
    is_manual_connection           = false
    private_connection_resource_id = azapi_resource.hub.id
    subresource_names              = ["amlworkspace"]
  }

  tags = var.tags

  depends_on = [ 
    azapi_resource.hub,
    azurerm_resource_group.rg, 
    azurerm_subnet.subnet-pe
  ]
}

## Create Private DNS Zone Virtual Network Link for Azure Machine Learning Notebooks ##
resource "azurerm_private_dns_zone_virtual_network_link" "azureml_notebooks" {
  provider = azurerm.core

  name                  = "${azapi_resource.hub.name}-notebooks-vnet-link"
  resource_group_name   = data.azurerm_private_dns_zone.azureml_notebooks.resource_group_name
  private_dns_zone_name = data.azurerm_private_dns_zone.azureml_notebooks.name
  virtual_network_id    = azurerm_virtual_network.vnet.id

  depends_on = [ 
    azapi_resource.hub,
    azurerm_resource_group.rg, 
    azurerm_virtual_network.vnet
  ]
}

## Create the Private Endpoint for Azure Machine Learning Notebooks ##
resource "azurerm_private_endpoint" "azureml_notebooks" {
  name                = "${azapi_resource.hub.name}-notebooks-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet-pe.id

  private_service_connection {
    name                           = "${azapi_resource.hub.name}-notebooks-pe-psc"
    is_manual_connection           = false
    private_connection_resource_id = azapi_resource.hub.id
    subresource_names              = ["amlworkspace"]
  }

  tags = var.tags

  depends_on = [ 
    azapi_resource.hub,
    azurerm_resource_group.rg, 
    azurerm_subnet.subnet-pe
  ]
}

#######################################################
## Azure AI Foundry Service Connection - Permissions ##
#######################################################

## OpenAI Services Connection ##
resource "azapi_resource" "openai_services_connection" {
  type = "Microsoft.MachineLearningServices/workspaces/connections@2024-07-01-preview"
  name = trim(azurerm_cognitive_account.this.name, "-")
  parent_id = azapi_resource.hub.id

  body = {
    properties = {
      category = "AzureOpenAI"
      target = azurerm_cognitive_account.this.endpoint
      authType = "ApiKey"
      credentials = {
        key = azurerm_cognitive_account.this.primary_access_key
      }
      isSharedToAll = true
      metadata = {
        ApiType = "Azure"
        ResourceId = azurerm_cognitive_account.this.id
      }
    }
  }
  response_export_values = ["*"]
}

## AI Search Services Connection ##
resource "azapi_resource" "aisearch_services_connection" {
  type = "Microsoft.MachineLearningServices/workspaces/connections@2024-07-01-preview"
  name = "${trim(azurerm_search_service.this.name, "-")}"
  parent_id = azapi_resource.hub.id

  body = {
    properties = {
      category = "CognitiveSearch"
      target = azurerm_search_service.this.name
      authType = "ApiKey"
      credentials = {
        key = azurerm_cognitive_account.this.primary_access_key
      }
      isSharedToAll = true
      metadata = {
        ApiType = "Azure"
        ResourceId = azurerm_cognitive_account.this.id
      }
    }
  }
  response_export_values = ["*"]
}

## Azure Storage Account Container for Data Upload ##
resource "azurerm_storage_container" "data_upload" {
  name                  = "foundry-data-upload"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

## Generate a SAS token for the Storage Account ##
data "azurerm_storage_account_sas" "this" {
  connection_string = azurerm_storage_account.this.primary_connection_string

  https_only = true
  
  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  # Configure the SAS validity period (start now, expires in 10 years)
  start   = "2025-01-01T00:00:00Z"
  expiry  = "2035-12-31T00:00:00Z"

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = true
    tag     = true
    filter  = true
  }
}

## Storage Account Services Connection at project ##
resource "azapi_resource" "storage_account_services_connection_project" {
  type = "Microsoft.MachineLearningServices/workspaces/connections@2024-07-01-preview"
  name = "${azurerm_storage_account.this.name}project"
  parent_id = azapi_resource.project.id

  body = {
    properties = {
      category = "AzureBlob"
      target = "https://${azurerm_storage_account.this.name}.blob.core.windows.net/${azurerm_storage_container.data_upload.name}"
      authType = "SAS"
      credentials = {
        sas = data.azurerm_storage_account_sas.this.sas
      }
      isSharedToAll = false
      metadata = {
        ApiType = "Azure"
        ResourceId = azurerm_storage_account.this.id
        ContainerName = azurerm_storage_container.data_upload.name
        AccountName = azurerm_storage_account.this.name
      }
    }
  }
  response_export_values = ["*"]

  depends_on = [ azurerm_storage_account.this, azurerm_storage_container.data_upload, data.azurerm_storage_account_sas.this ]
}

####################################
## Azure AI Foundry - Permissions ##
####################################

## Give access to AI Project to users ##
resource "azurerm_role_assignment" "ai_project_users" {
  for_each             = toset(var.genai_user_ids)
  principal_id         = each.value
  role_definition_name = "Owner"
  scope                = azapi_resource.project.id

  depends_on= [ azurerm_resource_group.rg, azapi_resource.project ]
}

###############################
## Azure AI Foundry - Output ##
###############################

## Output all properties of AI Project ##
output "ai_project_properties" {
  description = "All properties of the AI Project"
  value       = azapi_resource.project.output.properties
}

## Output all properties of AI Project ##
output "ai_project_id" {
  description = "All properties of the AI Project"
  value       = azapi_resource.project.output.properties.workspaceId
}

## Output SAS Token ##
output "sas_token" {
  description = "Azure Storage SAS Token"
  value       = nonsensitive(data.azurerm_storage_account_sas.this.sas)
}
