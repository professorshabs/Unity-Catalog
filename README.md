# Introduction 
Project on tech/feature test on personal capacity. It involves using Terraform to manage resources, and setup Unity Catalog.
Use unity catalog to monitor databricks/pipelines

# Setting Up Unity Catalog:
User guide:
1.	##Resources requirements in Azure: 
     1. Have a resource group (recommended)
     2. Create Storage Gen 2 (enable_blob_hierarch =true) with a container for metastore
     3. Create Premium Databricks workspace
     4. Create Azure databricks access connector and grant it access to Gen 2 storage by going to IAM on Gen 2 and add role

# Setup Azure CLI and Terraform
Download Azure CLI and Terraform from offical websitea.
    Azure CLI login commands:
        - az login OR az login --use-device-code OR az login --tenant <tenant ID>
        - az extension add --upgrade -n account
        - az account show


    Terraform important commands:
        - terraform validate
        - terraform plan
        - terraform apply


# Contribute
TODO: Explain how other users and developers can contribute to make your code better. 

## Related Documentaion links

These are some other Docs/software related to this projects:

* [Terraform](https://developer.hashicorp.com/terraform/install) - documentation source for Terraform installation
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt) - az for linux
* [Unity Calalog](https://learn.microsoft.com/en-us/azure/databricks/data-governance/unity-catalog/) - Doc to understand Unity Catalog
* [System Tables](https://learn.microsoft.com/en-us/azure/databricks/administration-guide/system-tables/) - Doc for system tables

