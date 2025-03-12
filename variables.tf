################################
## Azure Provider - Variables ##
################################

# Azure authentication variables

variable "azure-subscription-customer-id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "azure-subscription-core-id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "azure-client-id" {
  type        = string
  description = "Azure Client ID"
}

variable "azure-client-secret" {
  type        = string
  description = "Azure Client Secret"
}

variable "azure-tenant-id" {
  type        = string
  description = "Azure Tenant ID"
}

#############################
## Application - Variables ##
#############################

# company name 
variable "company" {
  type        = string
  description = "This variable defines the company name used to build resources"
  default     = "kopicloud"
}

# application name 
variable "app_name" {
  type        = string
  description = "This variable defines the application name used to build resources"
}

# environment
variable "environment" {
  type        = string
  description = "This variable defines the environment to be built"
}

variable "tags" {
  type        = map(string)
  description = "The collection of tags to be applied against all resources created by the module"
  default     = {}
}

#####################
## DNS - Variables ##
#####################

variable "private_dns_resource_group" {
  type        = string
  description = "The Resource Group where Private DNS Zones were created"
  default     = "root-core-rg"  
}