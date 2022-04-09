provider "azurerm" {
  features {}
}
terraform {
  backend "azurerm" {
  }
}

#########################################################
##
## Core Infra Resource Group
##
#########################################################
module "coreInfraResourceGroup" {
  #Notice the source here. You can reference modules this way or locally. We'll go with locally for this case but wanted to show the alternative so you can use tags/versioning for your modules
  #source                  = "git::https://mattsOrg@dev.azure.com/matts/infrastructure/_git/terraform-module-resourceGroup?ref=1.0.4"
  source                  = "../modules/resourceGroup/"
  rg_name                 = "rg-infra-${terraform.workspace}-001"
  rg_location             = lookup(var.region, terraform.workspace)
  management_lock_enabled = lookup(var.management_lock_enabled, terraform.workspace)
  management_lock_name    = lookup(var.management_lock_name, terraform.workspace)
  management_lock_level   = lookup(var.management_lock_level, terraform.workspace)
  tags                    = local.common_tags
}

#########################################################
##
## Core Infra Storage Account
##
#########################################################
module "coreInfraStorageAccount" {
  source                  = "../modules/resourceGroup/"
  resource_group_name              = module.coreInfraResourceGroup.resource_group_name
  resource_group_location          = module.coreInfraResourceGroup.resource_group_location
  storage_account_name             = "stinfra${terraform.workspace}001"
  account_tier                     = lookup(var.storage_account_tier, terraform.workspace)
  storage_account_replication_type = lookup(var.storage_account_replication_type, terraform.workspace)
  min_tls_version                  = lookup(var.storage_account_min_tls_version, terraform.workspace)
  tags                             = local.common_tags
  network_rules                    = var.network_rules
}
