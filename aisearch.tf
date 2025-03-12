#################################
## Azure AI Search - Resources ##
#################################

## Deploy Azure AI Search Service
resource "azurerm_search_service" "this" {
  name                = "${lower(var.app_name)}${var.environment}-ai-search"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  identity {
    type = "SystemAssigned"
  }

  sku             = var.azure_ai_sku
  replica_count   = var.azure_ai_replica_count
  partition_count = var.azure_ai_partition_count

  public_network_access_enabled = var.azure_ai_public_network_access_enabled
  allowed_ips                   = var.azure_ai_allowed_ips
  local_authentication_enabled  = true
  authentication_failure_mode   = "http403"
  network_rule_bypass_option    = "AzureServices"

  lifecycle {
    ignore_changes = [
      public_network_access_enabled,
      allowed_ips,
      tags,
    ]
  }

  tags = var.tags

  depends_on = [ 
    azurerm_resource_group.rg, 
    azurerm_virtual_network.vnet,
    azurerm_subnet.subnet-pe
  ]
}

# Create Private DNS Zone Virtual Network Link
resource "azurerm_private_dns_zone_virtual_network_link" "ai_search" {
  provider = azurerm.core

  name                  = "${azurerm_search_service.this.name}-vnet-link"
  resource_group_name   = data.azurerm_private_dns_zone.ai_search.resource_group_name
  private_dns_zone_name = data.azurerm_private_dns_zone.ai_search.name
  virtual_network_id    = azurerm_virtual_network.vnet.id

  depends_on = [ 
    azurerm_search_service.this,
    azurerm_resource_group.rg, 
    azurerm_virtual_network.vnet
  ]
}

# Create the Private Endpoint
resource "azurerm_private_endpoint" "search" {
  name                = "${azurerm_search_service.this.name}-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet-pe.id

  private_service_connection {
    name                           = "${azurerm_search_service.this.name}-pe-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_search_service.this.id
    subresource_names              = ["searchService"]
  }

  tags = var.tags

  depends_on = [ 
    azurerm_search_service.this,
    azurerm_resource_group.rg, 
    azurerm_subnet.subnet-pe
  ]
}

# Create the DNS A Record for the Private Endpoint
resource "azurerm_private_dns_a_record" "search" {
  provider = azurerm.core

  name                = azurerm_search_service.this.name
  zone_name           = data.azurerm_private_dns_zone.ai_search.name
  resource_group_name = data.azurerm_private_dns_zone.ai_search.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.search.private_service_connection[0].private_ip_address]

  depends_on = [ azurerm_search_service.this ]
}

##################################
## Azure AI Search - Variables  ##
##################################

# Azure AI Search SKU
variable "azure_ai_sku" {
  description = "The pricing tier of the search service you want to create (for example, basic or standard)."
  default     = "standard"
  type        = string
  validation {
    condition     = contains(["free", "basic", "standard", "standard2", "standard3", "storage_optimized_l1", "storage_optimized_l2"], var.azure_ai_sku)
    error_message = "The sku must be one of the following values: free, basic, standard, standard2, standard3, storage_optimized_l1, storage_optimized_l2."
  }
}

# Azure AI Search Replica Count
variable "azure_ai_replica_count" {
  type        = number
  description = "Replicas distribute search workloads across the service. You need at least two replicas to support the high availability of query workloads (not applicable to the free tier)."
  default     = 1
  validation {
    condition     = var.azure_ai_replica_count >= 1 && var.azure_ai_replica_count <= 12
    error_message = "The replica_count must be between 1 and 12."
  }
}

variable "azure_ai_partition_count" {
  type        = number
  description = "Partitions allow for scaling of document count as well as faster indexing by sharding your index over multiple search units."
  default     = 1
  validation {
    condition     = contains([1, 2, 3, 4, 6, 12], var.azure_ai_partition_count)
    error_message = "The partition_count must be one of the following values: 1, 2, 3, 4, 6, 12."
  }
}

variable "azure_ai_public_network_access_enabled" {
  type        = bool
  description = "Enable public network access"
  default     = false
}

variable "azure_ai_allowed_ips" {
  type        = list(string)
  description = "One or more IP Addresses, or CIDR Blocks which should be able to access the AI Search service"
  default     = []
}

##############################
## Azure AI Search - Output ##
##############################

## OUTPUT AI Search Name ##
output "AI_Search_Name" {
  value = azurerm_search_service.this.name
}

## OUTPUT AI Search Key (Remove in PROD) ##
output "AI_Search_Key" {
  value = nonsensitive(azurerm_search_service.this.primary_key)
}
