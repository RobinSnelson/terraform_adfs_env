data "terraform_remote_state" "adfsenv" {
  backend = "azurerm"
  config = {

    resource_group_name  = "remote-state"
    storage_account_name = "rgsazremotestate"
    container_name       = "tfstate"
    key                  = "adfs.tfstate"
  }

}