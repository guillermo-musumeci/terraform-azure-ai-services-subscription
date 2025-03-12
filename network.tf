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

# Create the NSG for the Subnet
resource "azurerm_network_security_group" "core_services" {
  name                = "${lower(var.app_name)}-${var.environment}-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  security_rule {
     name                       = "Allow-HTTPS"
     priority                   = 1000
     direction                  = "Inbound"
     access                     = "Allow"
     protocol                   = "Tcp"
     source_port_range          = "*"
     destination_port_range     = "443"
     source_address_prefix      = var.internal-source-address-cidr
     destination_address_prefix = "*"
  }

  security_rule {
     name                       = "Allow-HTTP"
     priority                   = 1010
     direction                  = "Inbound"
     access                     = "Allow"
     protocol                   = "Tcp"
     source_port_range          = "*"
     destination_port_range     = "80"
     source_address_prefix      = var.internal-source-address-cidr
     destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1020
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.internal-source-address-cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1030
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.internal-source-address-cidr
    destination_address_prefix = "*"
  }

  security_rule {
     name                       = "Allow-ICMP"
     priority                   = 1040
     direction                  = "Inbound"
     access                     = "Allow"
     protocol                   = "Icmp"
     source_port_range          = "*"
     destination_port_range     = "*"
     source_address_prefix      = var.internal-source-address-cidr
     destination_address_prefix = "*"
  }

  tags = var.tags
}

# Attach NSG to Subnet
resource "azurerm_subnet_network_security_group_association" "subnet" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.core_services.id
}

# Attach NSG to Private Endpoint Subnet
resource "azurerm_subnet_network_security_group_association" "subnet_pe" {
  subnet_id                 = azurerm_subnet.subnet-pe.id
  network_security_group_id = azurerm_network_security_group.core_services.id
}

# Attach NSG to WebApp Subnet
resource "azurerm_subnet_network_security_group_association" "subnet_appservices" {
  subnet_id                 = azurerm_subnet.subnet-appservices.id
  network_security_group_id = azurerm_network_security_group.core_services.id
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

variable "internal-source-address-cidr" {
  type        = string
  description = "The CIDR for the internal network"
  default     = "10.0.0.0/8"
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
