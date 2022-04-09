terraform {
  required_version = "~> 0.14.7"
  required_providers {
    azurerm = "~>2.72.0"
    random  = "~>3.1.0"
    null    = "~>3.1.0"
    azuread = ">=1.4.0"
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">=0.1.2"
    }
  }
}
