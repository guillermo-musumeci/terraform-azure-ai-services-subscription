##############################
## Azure OpenAI - Resources ##
##############################

## Create Azure Cognitive Account ##
resource "azurerm_cognitive_account" "this" {
  name                = "${lower(var.app_name)}${var.environment}-aca"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kind                = var.openai_cognitive_account_kind
  sku_name            = var.openai_cognitive_account_sku_name

  public_network_access_enabled      = var.openai_public_network_access_enabled
  outbound_network_access_restricted = var.openai_outbound_network_access_restricted

  custom_subdomain_name      = var.openai_custom_subdomain_name
  dynamic_throttling_enabled = var.openai_dynamic_throttling_enabled

  identity {
    type = "SystemAssigned"
  }

  network_acls {
    bypass         = "AzureServices" 
    default_action = "Deny"
    ip_rules       = var.openai_network_acls_ip_rules
    virtual_network_rules {
      subnet_id = azurerm_subnet.subnet.id
    }
    virtual_network_rules {
      subnet_id = azurerm_subnet.subnet-pe.id
    }
  }

  tags = var.tags

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet,
    azurerm_subnet.subnet,
    azurerm_subnet.subnet-pe
  ]
}

## Create Private DNS Zone Virtual Network Link for OpenAI ## 
resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  provider = azurerm.core
  
  name                  = "${azurerm_cognitive_account.this.name}-link"
  resource_group_name   = data.azurerm_private_dns_zone.openai.resource_group_name
  private_dns_zone_name = data.azurerm_private_dns_zone.openai.name
  virtual_network_id    = azurerm_virtual_network.vnet.id

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_virtual_network.vnet,
    azurerm_cognitive_account.this
  ]
}

## Create the Private Endpoints  for OpenAI ##
resource "azurerm_private_endpoint" "openai" {
  name                = "${azurerm_cognitive_account.this.name}-pe"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.subnet-pe.id

  private_service_connection {
    name                           = "${azurerm_cognitive_account.this.name}-psc"
    private_connection_resource_id = azurerm_cognitive_account.this.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.openai.id]
  }
  
  tags = var.tags

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_subnet.subnet-pe,
    azurerm_cognitive_account.this
  ]
}

## Create the Azure Cognitive Deployment ##
resource "azurerm_cognitive_deployment" "this" {
  for_each = {
    for key, value in var.openai_cognitive_deployment :
    key => value
  }

  name = "${lower(var.app_name)}${var.environment}"
  
  cognitive_account_id = azurerm_cognitive_account.this.id

  model {
    format  = each.value.format
    name    = each.value.type
    version = each.value.version
  }

  sku {
    name = each.value.scale_type
    capacity = each.value.capacity
  }

  depends_on = [
    azurerm_resource_group.rg,
    azurerm_cognitive_account.this
  ]
}

##############################
## Azure OpenAI - Variables ##
##############################

variable "openai_cognitive_deployment" {
  description = "List of Cognitive Deployments"
  type = list(object({
    name       = string
    format     = string
    type       = string
    version    = string
    scale_type = string
    capacity   = number
  }))
  default = []
}

variable "openai_custom_subdomain_name" {
  type        = string
  description = "Specifies the Kind for this Cognitive Service Account"
  default     = "OpenAI"
}

variable "openai_cognitive_account_kind" {
  type        = string
  description = "Specifies the Kind for this Cognitive Service Account"
  default     = "OpenAI"
}

variable "openai_cognitive_account_sku_name" {
  type        = string
  description = "Specifies the SKU Name for this Cognitive Service Account"
  default     = "S0"
}

variable "openai_dynamic_throttling_enabled" {
  type        = bool
  description = "Specifies whether dynamic throttling is enabled for this Cognitive Service Account"
  default     = false
}

variable "openai_public_network_access_enabled" {
  type        = bool
  description = "Enable public network access"
  default     = false
}

variable "openai_outbound_network_access_restricted" {
  type        = bool
  description = "Whether outbound network access is restricted for the Cognitive Account"
  default     = false
}

variable "openai_network_acls_default_action" {
  type        = string
  description = "The Default Action to use when no rules match from ip_rules / virtual_network_rules. Possible values are Allow and Deny."
  default     = "Deny"
}

variable "openai_network_acls_ip_rules" {
  type        = list(string)
  description = "One or more IP Addresses, or CIDR Blocks, which should be able to access the Cognitive Account."
  default     = []
}

###########################
## Azure OpenAI - Output ##
###########################

output "OpenAI_Endpoint" {
  value = azurerm_cognitive_account.this.endpoint
}

output "OpenAI_Key" {
  value = nonsensitive(azurerm_cognitive_account.this.primary_access_key)
}

output "OpenAI_Deployment" {
  value = azurerm_cognitive_deployment.this
}