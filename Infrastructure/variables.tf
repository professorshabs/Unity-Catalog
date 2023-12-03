# Variable for Databricks account ID
variable "databricks_account_id" {
  description = "The Databricks account ID"
  default = "Replace this with databricks ID" #000c0d00-00f0-0d0f-00ee-fbd00c0f0b00
  sensitive   = true # Indicates this variable should be treated as sensitive
}

variable "location_region" {
    description = "Where do want this resource to be hosted?:east US"
    type = string
}

variable "resource_group_name" {
    description = "resource group name:"
    default = "Shabs_Databricks_lakehouse"
    type = string
}

variable "storage_account_name" {
    description = "Datalake Name:"
    default = "shabsdatalake001"
  
}
variable "access_connector_name" {
    description = "access connector name"
    default = "shabs_accessconnector_env001"
  
}

variable "workspace_name" {
  description = "Name of databricks workspace:"
  default = "shabs_databricks_env001"
}
variable "metastore_name" {
  description = "Metastore name:"
  default = "primary_metastore_eastus"
}

variable "catalog_name" {
  description = "Name of catalog:"
  default = "fdl_lakehouse"
}