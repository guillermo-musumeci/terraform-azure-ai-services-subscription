## Create Log Analytics for Application Insights ##
resource "azurerm_log_analytics_workspace" "foundry" {
  name                = "${lower(var.app_name)}${var.environment}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

## Create Application Insights for Azure AI Foundry ##
resource "azurerm_application_insights" "foundry" {
  name                = "${lower(var.app_name)}${var.environment}-app-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.foundry.id
  application_type    = "web"
}
