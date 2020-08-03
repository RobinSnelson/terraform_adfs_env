provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "bastion_rg" {
  name     = var.bastion_rg
  location = var.location

}

resource "azurerm_public_ip" "bastion-pip" {
  name                = "bastion-pip"
  resource_group_name = var.bastion_rg
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [
    "azurerm_resource_group.bastion_rg"
  ]

}

resource "azurerm_bastion_host" "bastion_host" {
  name                = "bastion-host"
  resource_group_name = var.bastion_rg
  location            = var.location

  ip_configuration {
    name                 = "adfs_bastion"
    subnet_id            = data.terraform_remote_state.adfsenv.outputs.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion-pip.id

  }
}

