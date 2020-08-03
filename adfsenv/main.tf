provider "azurerm" {
  features {}
}

#create the resource group to contain all the resources
resource "azurerm_resource_group" "main_rg" {
  name     = "${var.project_name}-rg"
  location = var.default_location

  tags = {
    environment = "development"
    project     = "Adfs_Environment"
    Asset_type  = "Resource_Group"
  }

}

#create the main virtual network for the environment
resource "azurerm_virtual_network" "main_vnet" {
  name                = "${var.project_name}-vnet"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = var.default_location

  address_space = [
    "${var.main_vnet_address_space}"
  ]

  tags = {
    environment = "development"
    project     = "Adfs_Environment"
    Asset_type  = "Virtual_Network"
  }
}

#create the subnet for the DMZ resources

resource "azurerm_subnet" "dmz_subnet" {
  name                 = "${var.dmz_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name



  address_prefixes = [
    "${var.dmz_subnet_address_space}"
  ]

}

#create the subnet for the internal resources

resource "azurerm_subnet" "internal_subnet" {
  name                 = "${var.internal_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name

  address_prefixes = [
    "${var.internal_subnet_address_space}"
  ]

}


#Subnet for Bastion host server

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.main_vnet.name

  address_prefixes = [
    "${var.bastion_subnet_address_space}"
  ]

}

#availability set for the WAP internal servers
resource "azurerm_availability_set" "dmz_availability_set" {
  name                         = "${var.dmz_prefix}-${var.wap_dmz_prefix}-avail-set"
  resource_group_name          = azurerm_resource_group.main_rg.name
  location                     = var.default_location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5

  tags = {
    environment = "development"
    project     = "Adfs_Environment"
    Asset_type  = "Availability Set"
  }

}

#availability set for the ADFS internal servers
resource "azurerm_availability_set" "adfs_internal_availability_set" {
  name                         = "${var.internal_prefix}-${var.adfs_internal_prefix}-avail-set"
  resource_group_name          = azurerm_resource_group.main_rg.name
  location                     = var.default_location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5

  tags = {
    environment = "development"
    project     = "Adfs_Environment"
    Asset_type  = "Availability Set"
  }

}

#availability set for the ADDS internal servers
resource "azurerm_availability_set" "adds_internal_availability_set" {
  name                         = "${var.internal_prefix}-${var.adds_internal_prefix}-avail-set"
  resource_group_name          = azurerm_resource_group.main_rg.name
  location                     = var.default_location
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5

  tags = {
    environment = "development"
    project     = "Adfs_Environment"
    Asset_type  = "Availability Set"
  }

}

#network security  group to manage traffic for the DMZ subnet
resource "azurerm_network_security_group" "dmz_nsg" {
  name                = "${var.dmz_prefix}-nsg"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = var.default_location

  tags = {
    environment = "development"
    project     = "Adfs_Environment"
    Asset_type  = "Network Security Group"

  }

}

#HTTP rule for http traffic coming into the DMZ
resource "azurerm_network_security_rule" "dmz_nsg_http_rule" {
  name                        = "Allow_HTTP"
  priority                    = 300
  direction                   = "inbound"
  access                      = "allow"
  protocol                    = "tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main_rg.name
  network_security_group_name = azurerm_network_security_group.dmz_nsg.name

}

resource "azurerm_subnet_network_security_group_association" "DMZ_NSG_Dubnet_assoc" {
  subnet_id                 = azurerm_subnet.dmz_subnet.id
  network_security_group_id = azurerm_network_security_group.dmz_nsg.id

}

resource "azurerm_storage_account" "storage_account" {
  name                     = "adfsenvbootdiags"
  location                 = var.default_location
  resource_group_name      = azurerm_resource_group.main_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

}

module "wapservers" {
  source = "./wapservers"

  project_name                = var.project_name
  resource_group              = azurerm_resource_group.main_rg.name
  default_location            = var.default_location
  dmz_prefix                  = var.dmz_prefix
  dmz_subnet_address_space    = var.dmz_subnet_address_space
  wap_dmz_prefix              = var.wap_dmz_prefix
  wap_server_count            = var.adfs_server_count
  admin_password              = ******** Need to add a password here or link to a password such as a Azure vault ************************
  dmz_subnet_id               = azurerm_subnet.dmz_subnet.id
  dmz_availability_set_id     = azurerm_availability_set.dmz_availability_set.id
  bootdiagnostics_storage_uri = azurerm_storage_account.storage_account.primary_blob_endpoint
}

module "adfservers" {
  source = "./adfsservers"

  project_name                  = var.project_name
  resource_group                = azurerm_resource_group.main_rg.name
  default_location              = var.default_location
  internal_prefix               = var.internal_prefix
  internal_subnet_address_space = var.internal_subnet_address_space
  adfs_internal_prefix          = var.adfs_internal_prefix
  adfs_server_count             = var.adfs_server_count
  admin_password                = ******** Need to add a password here or link to a password such as a Azure vault ************************
  internal_subnet_id            = azurerm_subnet.internal_subnet.id
  adfs_availability_set_id      = azurerm_availability_set.adfs_internal_availability_set.id
  bootdiagnostics_storage_uri   = azurerm_storage_account.storage_account.primary_blob_endpoint

}

module "addsservers" {
  source = "./addsservers"

  project_name                  = var.project_name
  resource_group                = azurerm_resource_group.main_rg.name
  default_location              = var.default_location
  internal_prefix               = var.internal_prefix
  internal_subnet_address_space = var.internal_subnet_address_space
  adds_internal_prefix          = var.adds_internal_prefix
  adds_server_count             = var.adds_server_count
  admin_password                = ******** Need to add a password here or link to a password such as a Azure vault ************************
  internal_subnet_id            = azurerm_subnet.internal_subnet.id
  adds_availability_set_id      = azurerm_availability_set.adds_internal_availability_set.id
  bootdiagnostics_storage_uri   = azurerm_storage_account.storage_account.primary_blob_endpoint

}
