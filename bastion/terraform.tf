terraform {
  backend "azurerm" {
    resource_group_name  = "remote-state"
    storage_account_name = "rgsazremotestate"
    container_name       = "tfstate"
    key                  = "bastion.tfstate"
  }
}