#########################################################
## Required Vairables
#########################################################

variable "application_name" {
  default = "myapp"
}

# Regional Mappings
variable "region" {
  type = map(any)
}

variable "region_shortname" {
  description = "Azure region alias used for naming convention"
}

# Local variables
locals {
  common_tags = {
    Environment     = terraform.workspace
    ApplicationName = var.application_name
    Approver        = ""
    DR              = ""
    Owner           = ""
    Requester       = ""
    CostCenter      = ""
    Department      = ""
  }
}

#########################################################
## Storage Account variables
#########################################################

variable "storage_account_tier" {
  type        = map(any)
  description = "Associate environment with Storage Account tier"

  default = {
    dev  = "Standard"
    prod = "Standard"
    uat  = "Standard"
  }
}
variable "storage_account_min_tls_version" {
  type        = map(any)
  description = "Associate environment with Storage Account min tls version"

  default = {
    dev  = "TLS1_2"
    prod = "TLS1_2"
    uat  = "TLS1_2"
  }
}
variable "storage_account_replication_type" {
  type        = map(any)
  description = "Associate environment with Storage Account replication type"

  default = {
    dev  = "GRS"
    prod = "GRS"
    uat  = "GRS"
  }
}
variable "network_rules" {
  description = "Network rules restricting access to the storage account."

  default = {
    default_action = "Allow"
    ip_rules       = []
    subnet_ids     = []
    bypass         = ["AzureServices"]
  }
}

#########################################################
## Management Lock variables
#########################################################

variable "management_lock_enabled" {
  type        = map(any)
  description = "Enable management lock on resource group"

  default = {
    dev  = false
    prod = true
    uat  = true
  }
}

variable "management_lock_name" {
  type        = map(any)
  description = "Specifies the name of the Management Lock"

  default = {
    dev  = "management-lock"
    prod = "management-lock"
    uat  = "management-lock"
  }
}

variable "management_lock_level" {
  type        = map(any)
  description = "Specifies the Level to be used for this Lock"

  default = {
    dev  = "CanNotDelete"
    prod = "CanNotDelete"
    uat  = "CanNotDelete"
  }
}