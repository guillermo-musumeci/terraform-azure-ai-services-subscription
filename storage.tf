#################################
## Storage Account - Resources ##
#################################

## Create Azure Storage Account ##
resource "azurerm_storage_account" "this" {
  name                     = "${lower(var.app_name)}${var.environment}st"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  account_kind             = var.account_kind
  access_tier              = var.access_tier
  is_hns_enabled           = var.enable_hierarchical_namespace

  https_traffic_only_enabled        = true
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true

  identity {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = [ azurerm_user_assigned_identity.this.id ]
  }

  public_network_access_enabled = var.storage_public_network_access_enabled
  network_rules {
    default_action             = var.storage_account_network_rules_action
    ip_rules                   = var.storage_account_network_rules_ip_rules
    virtual_network_subnet_ids = [azurerm_subnet.subnet.id]
  }

  blob_properties {
    dynamic "delete_retention_policy" {
      for_each = var.blob_delete_retention_policy_days != 0 ? [1] : []

      content {
        days = var.blob_delete_retention_policy_days
      }
    }

    dynamic "container_delete_retention_policy" {
      for_each = var.container_delete_retention_policy_days != 0 ? [1] : []

      content {
        days = var.container_delete_retention_policy_days
      }
    }

    versioning_enabled = var.enable_blob_versioning
    
    last_access_time_enabled = true

    cors_rule{
      allowed_headers = ["*"]
      allowed_methods = ["GET","HEAD","POST","PUT"]
      allowed_origins = ["*"]
      exposed_headers = ["*"]
      max_age_in_seconds = 200
    }
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  tags = var.tags

  depends_on = [ 
    azurerm_user_assigned_identity.this, 
    azurerm_resource_group.rg,
    azurerm_subnet.subnet-pe
  ]
}

## Create a Private Endpoint in the CUSTOMER Account for BLOB ##
resource "azurerm_private_endpoint" "blob" {
  name                = "${azurerm_storage_account.this.name}-blob-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet-pe.id

  private_service_connection {
    name                           = "${azurerm_storage_account.this.name}-blob-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  depends_on = [azurerm_storage_account.this]
}

## Create DNS A Record for the Private Endpoint in the CORE Account for BLOB ##
resource "azurerm_private_dns_a_record" "blob" {
  provider = azurerm.core

  name                = azurerm_storage_account.this.name
  zone_name           = data.azurerm_private_dns_zone.blob.name
  resource_group_name = data.azurerm_private_dns_zone.blob.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.blob.private_service_connection.0.private_ip_address]

  depends_on = [
    azurerm_storage_account.this,
    azurerm_private_endpoint.blob
  ]
}

## Create Private Endpoint in the CUSTOMER Account for DFS ##
resource "azurerm_private_endpoint" "dfs" {
  name                = "${azurerm_storage_account.this.name}-dfs-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet-pe.id

  private_service_connection {
    name                           = "${azurerm_storage_account.this.name}-dfs-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["dfs"]
  }

  depends_on = [azurerm_storage_account.this]
}

## Create DNS A Record for the Private Endpoint in the CORE Account for DFS ##
resource "azurerm_private_dns_a_record" "dfs" {
  provider = azurerm.core

  name                = azurerm_storage_account.this.name
  zone_name           = data.azurerm_private_dns_zone.dfs.name
  resource_group_name = data.azurerm_private_dns_zone.dfs.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.dfs.private_service_connection.0.private_ip_address]

  depends_on = [ azurerm_storage_account.this, azurerm_private_endpoint.dfs ]
}

## Create Private Endpoint in the CUSTOMER Account for Table ##
resource "azurerm_private_endpoint" "table" {
  name                = "${azurerm_storage_account.this.name}-table-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet-pe.id

  private_service_connection {
    name                           = "${azurerm_storage_account.this.name}-table-psc"
    private_connection_resource_id = azurerm_storage_account.this.id
    is_manual_connection           = false
    subresource_names              = ["table"]
  }

  depends_on = [azurerm_storage_account.this]
}

## Create DNS A Record for the Private Endpoint in the CORE Account for Table ##
resource "azurerm_private_dns_a_record" "table" {
  provider = azurerm.core

  name                = azurerm_storage_account.this.name
  zone_name           = data.azurerm_private_dns_zone.table.name
  resource_group_name = data.azurerm_private_dns_zone.table.resource_group_name
  ttl                 = 300
  records             = [azurerm_private_endpoint.table.private_service_connection.0.private_ip_address]

  depends_on = [ azurerm_storage_account.this, azurerm_private_endpoint.table ]
}

#################################
## Storage Account - Variables ##
#################################

variable "account_tier" {
  type        = string
  description = "(Required) Defines the Tier to use for this storage account. Valid options are Standard and Premium. For BlockBlobStorage and FileStorage accounts only Premium is valid. Changing this forces a new resource to be created."
  default     = "Standard"
}

variable "account_replication_type" {
  type        = string
  description = "(Required) Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS. Changing this forces a new resource to be created when types LRS, GRS, and RAGRS are changed to ZRS, GZRS, or RAGZRS and vice versa."
  default     = "RAGRS"
}

variable "account_kind" {
  type        = string
  description = "(Optional) Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2. Changing this forces a new resource to be created. Defaults to StorageV2."
  default     = "StorageV2"
}

variable "access_tier" {
  type        = string
  description = "(Optional) Defines the access tier for BlobStorage, FileStorage and StorageV2 accounts. Valid options are Hot and Cool, defaults to Hot."
  default     = "Hot"
}

variable "blob_delete_retention_policy_days" {
  type        = number
  description = "(Optional) Specifies the number of days that the blob should be retained, between 1 and 365 days. Defaults to 7."
  default     = 0
}

variable "container_delete_retention_policy_days" {
  type        = number
  description = "(Optional) Specifies the number of days that the container should be retained, between 1 and 365 days. Defaults to 7."
  default     = 0
}

variable "enable_blob_versioning" {
  type        = bool
  description = "(Optional) Is versioning enabled? Default to false"
  default     = false
}

variable "enable_hierarchical_namespace" {
  type        = bool
  description = "Whether or not to enable hierarchical namespaces for this storage account"
  default     = true
}

// this setting needs to be TRUE to avoid the context deadline exceeded error
variable "storage_public_network_access_enabled" {
  type        = bool
  description = "Enable or Disable public network access"
  default     = true
}

// this setting needs to be DENY to avoid the context deadline exceeded error
variable "storage_account_network_rules_action" {
  type        = string
  description = "Specifies the default action of allow or deny when no other rules match. Valid options are Deny or Allow."
  default     = "Deny"
}

variable "virtual_network_subnet_ids" {
  type        = list(string)
  description = "List of virtual network subnet ids"
  default     = []
}

variable "storage_account_network_rules_ip_rules" {
  type        = list(string)
  description = "List of public IP or IP ranges in CIDR Format. Only IPv4 addresses are allowed."
  default     = []
}

##############################
## Storage Account - Output ##
##############################

output "Storage_Account_Name" {
  value = azurerm_storage_account.this.name
}

output "Storage_Account_Keys" {
  value = nonsensitive(azurerm_storage_account.this.primary_access_key)
}