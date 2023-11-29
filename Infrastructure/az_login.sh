az login --use-device-code

az login --tenant f7c84ff5-9f06-4750-ad5b-d58e54563cfa
az extension add --upgrade -n account

az account show
terraform plan
terraform apply

az group list --query "[?name=='TerraformRG']"
terraform destroy 