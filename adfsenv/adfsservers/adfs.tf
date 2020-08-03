#Load balancer for the Adfs Servers
resource "azurerm_lb" "int_lb" {
  name                = "${var.internal_prefix}-lb"
  resource_group_name = var.resource_group
  location            = var.default_location


  frontend_ip_configuration {
    name                          = "${var.internal_prefix}-lb-ipconf"
    private_ip_address_allocation = "static"
    subnet_id                     = var.internal_subnet_id
  }

  tags = {
    environment = "development"
    area        = "Internal"
    project     = "Adfs_Environment"
    Asset_type  = "Load Balancer"

  }
}

#Loadbalancer back end pool for the Adfs servers 
resource "azurerm_lb_backend_address_pool" "int_lb_backend_pool" {
  name                = "${var.internal_prefix}-lb-backend-pool"
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.int_lb.id

}

resource "azurerm_lb_probe" "adfs_lb_probe" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.int_lb.id
  name                = "adfshttpsprobe"
  port                = 80

}

resource "azurerm_lb_rule" "adfs_lb_https_rule" {
  resource_group_name            = var.resource_group
  loadbalancer_id                = azurerm_lb.int_lb.id
  name                           = "adfshttpsrule"
  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 443
  backend_address_pool_id        = azurerm_lb_backend_address_pool.int_lb_backend_pool.id
  frontend_ip_configuration_name = "${var.internal_prefix}-lb-ipconf"
  probe_id = azurerm_lb_probe.adfs_lb_probe.id
}

#Network Interfaces for the ADFS VM's
resource "azurerm_network_interface" "int_adfs_vm_interface" {
  name                = "${var.internal_prefix}-${var.adfs_internal_prefix}-${format("%02d", count.index + 1)}-int"
  resource_group_name = var.resource_group
  location            = var.default_location
  count               = var.adfs_server_count

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.internal_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.internal_subnet_address_space, count.index + 20)

  }

  tags = {
    environment = "development"
    area        = "Internal"
    project     = "Adfs_Environment"
    Asset_type  = "Network Interface"

  }

}

#ADFS VM's the number of these servers is maintained by the ADFS Server count variable
resource "azurerm_windows_virtual_machine" "int_adfs_vm" {
  name                     = "${var.internal_prefix}-${var.adfs_internal_prefix}-${format("%02d", count.index + 1)}-vm"
  resource_group_name      = var.resource_group
  location                 = var.default_location
  size                     = "Standard_B2s"
  admin_username           = "sysadmin"
  admin_password           = var.admin_password
  availability_set_id      = var.adfs_availability_set_id
  count                    = var.adfs_server_count
  provision_vm_agent       = true
  enable_automatic_updates = true

  tags = {
    environment = "development"
    area        = "Internal"
    project     = "Adfs_Environment"
    Asset_type  = "VM"

  }

  network_interface_ids = [
    azurerm_network_interface.int_adfs_vm_interface[count.index].id
  ]

  os_disk {
    name                 = "${var.internal_prefix}-${var.adfs_internal_prefix}-${format("%02d", count.index + 1)}-vm-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = var.bootdiagnostics_storage_uri
  }
}

#adding servers to the Adfs Laod Balancer backend pool
resource "azurerm_network_interface_backend_address_pool_association" "Adfs_backendpool" {
  network_interface_id    = azurerm_network_interface.int_adfs_vm_interface[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.int_lb_backend_pool.id
  count                   = var.adfs_server_count

}

resource "azurerm_virtual_machine_extension" "vm_ext" {
  name                 = "Install_IIS"
  virtual_machine_id   = azurerm_windows_virtual_machine.int_adfs_vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  count                = var.adfs_server_count

  settings = <<SETTINGS
  {
      "fileUris" : ["https://raw.githubusercontent.com/RobinSnelson/azuredevelopment/master/snippets/installWebServer.ps1"],
      "commandToExecute" : "start powershell -executionpolicy Unrestricted -file InstallWebServer.ps1"
  }
  SETTINGS

}