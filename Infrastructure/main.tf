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

#random number
resource "random_id" "suffix" {
  byte_length = 8
}

#Azure Storage account creation
resource "azurerm_storage_account" "storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
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
  name                = "shabs-kv-env${random_id.suffix.hex}"
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}


# This block creates a Databricks access connector.
resource "azurerm_databricks_access_connector" "access_connector" {
  name                = var.access_connector_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location


  identity {
    type = "SystemAssigned"
  }
}

# This block creates a metastore container.
resource "azurerm_storage_container" "unity_catalog" {
  name                  = "${local.prefix}${random_id.suffix.hex}"
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
  name                = var.workspace_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "premium"
}


#Single metastore per region for an organization  and  each workspace will have the same view of the data you manage in Unity Catalog.
resource "databricks_metastore" "metastore" {
  name = var.metastore_name
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
  name         = "metastore_storage_credentials"
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
  name = "external_storage_credential_${random_id.suffix.hex}"
  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.access_connector.id
  }
  comment = "Managed identity credential managed by TF"
  depends_on = [databricks_metastore.metastore]
}

resource "databricks_catalog" "catalog" {
  metastore_id = databricks_metastore.metastore.id
  name         = var.catalog_name
  comment      = "this catalog is managed by terraform"
  properties = {
    purpose = "testing"
  }
}
