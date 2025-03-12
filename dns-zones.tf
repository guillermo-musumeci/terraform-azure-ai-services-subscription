######################
## DNS - References ##
######################

## Reference to Private DNS Zone for OpenAI ##
data "azurerm_private_dns_zone" "openai" {
  provider = azurerm.core

  name                = "privatelink.openai.azure.com"
  resource_group_name = var.private_dns_resource_group
}

## Reference to Private DNS Zone for AI Search ##
data "azurerm_private_dns_zone" "ai_search" {
  provider = azurerm.core

  name                = "privatelink.search.windows.net"
  resource_group_name = var.private_dns_resource_group
}

## Reference to Private DNS Zone for SQL Server ##
data "azurerm_private_dns_zone" "sql_server" {
  provider = azurerm.core
 
  name                = "privatelink.database.windows.net"
  resource_group_name = var.private_dns_resource_group
}

## Reference to Private DNS Zone for Storage Blob ##
data "azurerm_private_dns_zone" "blob" {
  provider = azurerm.core

  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.private_dns_resource_group
}

## Reference to Private DNS Zone for Storage DFS ##
data "azurerm_private_dns_zone" "dfs" {
  provider = azurerm.core

  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = var.private_dns_resource_group
}

## Reference to Private DNS Zone for Storage Table ##
data "azurerm_private_dns_zone" "table" {
  provider = azurerm.core

  name                = "privatelink.table.core.windows.net"
  resource_group_name = var.private_dns_resource_group
}

## Reference to Private DNS Zone for AppServices (Function/WebApp) ##
data "azurerm_private_dns_zone" "appservices" {
  provider = azurerm.core

  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.private_dns_resource_group
}

## Reference to Private DNS Zone for KeyVault ##
data "azurerm_private_dns_zone" "keyvault" {
  provider = azurerm.core

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.private_dns_resource_group
}

## Private DNS Zone for Azure Machine Learning ##
data "azurerm_private_dns_zone" "azureml" {
  provider = azurerm.core

  name                = "privatelink.api.azureml.ms"
  resource_group_name = var.private_dns_resource_group
}

## Private DNS Zone for Azure Machine Learning Notebooks ##
data "azurerm_private_dns_zone" "azureml_notebooks" {
  provider = azurerm.core

  name                = "privatelink.notebooks.azure.net"
  resource_group_name = var.private_dns_resource_group
}

