# Terraform block defining required providers for Azure and Databricks
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.82.0"
    }
    databricks = {
      source = "databricks/databricks"
      version = "1.30.0"
    }
  }
}
# Variable for Databricks account ID
variable "databricks_account_id" {
  description = "The Databricks account ID"
  sensitive   = true # Indicates this variable should be treated as sensitive
}

# Locals block defining computed values
locals {
  location                  = "East US"
  resource_group_name       = "Shabs_Databricks_lakehouse"
  # client_id                 = data.azurerm_client_config.current.client_id
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  subscription_id           = data.azurerm_subscription.current.subscription_id
  databricks_workspace_host = azurerm_databricks_workspace.databricks.workspace_url
  databricks_workspace_id   = azurerm_databricks_workspace.databricks.workspace_id
  databricks_resource_group = azurerm_resource_group.rg.name
  # databricks_workspace_name = azurerm_databricks_workspace.databricks.name
  prefix                    = replace(replace(replace(lower(azurerm_resource_group.rg.name), "rg", ""), "-", ""),"_","")
}

# Azure provider block
provider "azurerm" {
  #subscription_id = local.subscription_id
  features {}
}

# Databricks provider block
provider "databricks" {
  host = local.databricks_workspace_host
}

# Databricks provider block with alias and configurations
provider "databricks" {
  alias                 = "accounts"
  host                  = "https://${local.databricks_workspace_host}"
  account_id            = var.databricks_account_id
}


# Data blocks to fetch Azure client configuration and subscription details
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "current" {}

# Azure resource group creation
resource "azurerm_resource_group" "rg" {
  name     = local.resource_group_name
  location = local.location
}

# resource "random_id" "storage_account_suffix" {
#   byte_length = 8
# }


# resource "azurerm_storage_account" "storage_account" {
#   name                     = "shabsdatalake${random_id.storage_account_suffix.hex}"
#   resource_group_name      = azurerm_resource_group.rg.name
#   location                 = local.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   account_kind             = "StorageV2"
#   is_hns_enabled           = true
# }

#Azure Storage account creation
resource "azurerm_storage_account" "storage_account" {
  name                     = "shabsdatalake001"
  resource_group_name      = local.databricks_resource_group
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
}

# This block creates an Azure storage account test container.
resource "azurerm_storage_container" "managed_container" {
  name                  = "raw"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"  # Set access type as needed
}


# This block creates an Azure key vault.
resource "azurerm_key_vault" "key_vault" {
  name                = "shabs-kv-env001"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}


# This block creates a Databricks access connector.
resource "azurerm_databricks_access_connector" "access_connector" {
  name                = "shabs_accessconnector_env001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location


  identity {
    type = "SystemAssigned"
  }
}

# This block creates a metastore container.
resource "azurerm_storage_container" "unity_catalog" {
  name                  = "${local.prefix}-container"
  storage_account_name  = azurerm_storage_account.storage_account.name
  container_access_type = "private"
}


# This block assigns a role to the Databricks access connector to allow it to access and manage data in the storage account.
resource "azurerm_role_assignment" "role_assign" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.access_connector.identity[0].principal_id
}

##Creating a workspace
resource "azurerm_databricks_workspace" "databricks" {
  name                = "shabs_databricks_env001"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"
}


#Single metastore per region for an organization  and  each workspace will have the same view of the data you manage in Unity Catalog.
resource "databricks_metastore" "metastore" {
  name = "primary_metastore_eastus"
  storage_root = format("abfss://%s@%s.dfs.core.windows.net/",
    azurerm_storage_container.unity_catalog.name,
    azurerm_storage_account.storage_account.name)
  owner         = "professorshabs@gmail.com"
  region        = azurerm_resource_group.rg.location
  force_destroy = true
}

##Giving access to metastore
resource "databricks_metastore_data_access" "primary" {
  provider     = databricks.accounts
  metastore_id = databricks_metastore.metastore.id
  name         = "metastore-cred"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.access_connector.id
  }
  depends_on = [databricks_metastore.metastore]
  is_default = true
}

# This block assigns the metastore to a workspace.
resource "databricks_metastore_assignment" "this" {
  provider             = databricks.accounts
  workspace_id         = local.databricks_workspace_id
  metastore_id         = databricks_metastore.metastore.id
}

# This block creates a storage credential.
resource "databricks_storage_credential" "storage_external_cred" {
  name = "storage_external_credential_001"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.access_connector.id
  }
  comment = "Managed identity credential managed by TF"
  depends_on = [databricks_metastore.metastore]
}

resource "databricks_catalog" "catalog" {
  metastore_id = databricks_metastore.metastore.id
  name         = "fdl_lakehouse"
  comment      = "this catalog is managed by terraform"
  properties = {
    purpose = "testing"
  }
}
