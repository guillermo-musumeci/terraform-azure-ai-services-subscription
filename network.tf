#########################
## Network - Resources ##
#########################

## Create a resource group for the app ##
resource "azurerm_resource_group" "rg" {
  name     = "${lower(var.app_name)}-${var.environment}-rg"
  location = var.location
  tags = var.tags
}

## Create the App VNET ##
resource "azurerm_virtual_network" "vnet" {
  name     = "${lower(var.app_name)}-${var.environment}-vnet"
  address_space       = [var.vnet-cidr]
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags = var.tags
}

## Create the App Subnet ## 
resource "azurerm_subnet" "subnet" {
  name                 = "${lower(var.app_name)}-${var.environment}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet-cidr]

  private_endpoint_network_policies = "Disabled"
  service_endpoints = ["Microsoft.CognitiveServices", "Microsoft.Storage", "Microsoft.KeyVault"]
}

## Create the Private Endpoint subnet ##
resource "azurerm_subnet" "subnet-pe" {
  name                 = "${lower(var.app_name)}-${var.environment}-subnet-pe"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet-pe-cidr]

  private_endpoint_network_policies = "Enabled"
  service_endpoints = ["Microsoft.CognitiveServices", "Microsoft.Storage", "Microsoft.KeyVault"]
}

# Create the App Services (Function/WebApp) subnet ##
resource "azurerm_subnet" "subnet-appservices" {
  name                 = "${lower(var.app_name)}-${var.environment}-subnet-appservices"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet-appservices-cidr]

  private_link_service_network_policies_enabled = true

  service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
  
  delegation {
    name = "function"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

#########################
## Network - Variables ##
#########################

# azure region
variable "location" {
  type        = string
  description = "Azure region where the resource group will be created"
  default     = "north europe"
}

variable "vnet-cidr" {
  type        = string
  description = "The CIDR of the VNET"
}

variable "subnet-cidr" {
  type        = string
  description = "The CIDR for the subnet"
}

variable "subnet-pe-cidr" {
  type        = string
  description = "The CIDR for the private endpoint subnet"
}

variable "subnet-appservices-cidr" {
  type        = string
  description = "The CIDR for the App Services (Function/WebApp) subnet"
}

######################
## Network - Output ##
######################

output "app_resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "app_vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "app_subnet_name" {
  value = azurerm_subnet.subnet.name
}

output "app_subnet_private_endpoint_name" {
  value = azurerm_subnet.subnet-pe.name
}

output "app_subnet_appservices_name" {
  value = azurerm_subnet.subnet-appservices.name
}
