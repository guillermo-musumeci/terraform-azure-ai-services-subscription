#############################
## Define Users and Groups ##
#############################

## Define a variable to hold the list of GenAI group IDs ##
variable "genai_groups_ids" {
  type    = list(string)
  default = []
}

## Define a variable to hold the list of GenAI user IDs ##
variable "genai_user_ids" {
  type    = list(string)
  default = []
}

###############################
## Resource Group Permisions ##
###############################

## Give access to Resource Group to users ##
resource "azurerm_role_assignment" "users_rg" {
  for_each             = toset(var.genai_user_ids)
  principal_id         = each.value
  role_definition_name = "Owner"
  scope                = azurerm_resource_group.rg.id
}

## Give access to Resource Group to groups ##
resource "azurerm_role_assignment" "groups_rg" {
  for_each             = toset(var.genai_groups_ids)
  principal_id         = each.value
  role_definition_name = "Owner"
  scope                = azurerm_resource_group.rg.id
}

###############################
## Permissions for AI Search ##
###############################

## Give access to OpenAI to AI Search ##
resource "azurerm_role_assignment" "ai_search_contributor_openai" {
  principal_id         = azurerm_cognitive_account.this.identity[0].principal_id
  role_definition_name = "Search Service Contributor"
  scope                = azurerm_search_service.this.id

  depends_on = [ azurerm_cognitive_account.this, azurerm_search_service.this ]
}

## Give access to OpenAI to AI Search ##
resource "azurerm_role_assignment" "ai_search_index_openai" {
  principal_id         = azurerm_cognitive_account.this.identity[0].principal_id
  role_definition_name = "Search Index Data Reader"
  scope                = azurerm_search_service.this.id

  depends_on = [ azurerm_cognitive_account.this, azurerm_search_service.this ]
}

############################
## Permissions for OpenAI ##
############################

## Give access to AI Search to OpenAI ##
resource "azurerm_role_assignment" "openai_contributor_ai_search" {
  principal_id         = azurerm_search_service.this.identity[0].principal_id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  scope                = azurerm_cognitive_account.this.id

  depends_on = [ azurerm_cognitive_account.this, azurerm_search_service.this ]
}

## Give permissions to Users as OpenAI Cognitive Services OpenAI Contributor ##
resource "azurerm_role_assignment" "openai_contributor_openai_users" {
  for_each             = toset(var.genai_user_ids)
  principal_id         = each.value
  role_definition_name = "Cognitive Services OpenAI Contributor"
  scope                = azurerm_cognitive_account.this.id

  depends_on = [ azurerm_cognitive_account.this ]
}

## Give permissions to Users as OpenAI Cognitive Services Contributor ##
resource "azurerm_role_assignment" "openai_contributor_users" {
  for_each             = toset(var.genai_user_ids)
  principal_id         = each.value
  role_definition_name = "Cognitive Services Contributor"
  scope                = azurerm_cognitive_account.this.id

  depends_on = [ azurerm_cognitive_account.this ]
}

#####################################
## Permissions for Storage Account ##
#####################################

## Give access to users to Storage Account Blob ##
resource "azurerm_role_assignment" "storage_blob_owner_users" {
  for_each             = toset(var.genai_user_ids)
  principal_id         = each.value
  role_definition_name = "Storage Blob Data Owner"
  scope                = azurerm_storage_account.this.id

  depends_on = [ azurerm_storage_account.this ]
}

## Give access to AI Search to Azure Storage Account ##
resource "azurerm_role_assignment" "storage_ai_search" {
  principal_id         = azurerm_search_service.this.identity[0].principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.this.id

  depends_on = [ azurerm_search_service.this, azurerm_storage_account.this ]
}

## Give access to Open AI to Azure Storage Account ##
resource "azurerm_role_assignment" "storage_openai" {
  principal_id         = azurerm_cognitive_account.this.identity[0].principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_account.this.id

  depends_on = [ azurerm_cognitive_account.this, azurerm_storage_account.this ]
}


