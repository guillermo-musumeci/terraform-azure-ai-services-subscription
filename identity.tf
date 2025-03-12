############################
## User Assigned Identity ##
############################

## Manages a User-Assigned Identity ##
resource "azurerm_user_assigned_identity" "this" {
  name                = "${lower(var.app_name)}-${var.environment}-identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = var.tags
  
  depends_on = [ azurerm_resource_group.rg ]
}
