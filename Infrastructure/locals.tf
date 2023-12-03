# Locals block defining computed values
locals {
  location                  = var.location_region
  resource_group_name       = var.resource_group_name
  # client_id                 = data.azurerm_client_config.current.client_id
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  subscription_id           = data.azurerm_subscription.current.subscription_id
  databricks_workspace_host = azurerm_databricks_workspace.databricks.workspace_url
  databricks_workspace_id   = azurerm_databricks_workspace.databricks.workspace_id
  databricks_resource_group = azurerm_resource_group.rg.name
  # databricks_workspace_name = azurerm_databricks_workspace.databricks.name
  prefix                    = replace(replace(replace(lower(azurerm_resource_group.rg.name), "rg", ""), "-", ""),"_","")
}