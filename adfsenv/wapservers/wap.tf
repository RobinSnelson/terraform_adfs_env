#Public IP for the WAP Loadbalancer
resource "azurerm_public_ip" "dmz_lb_public_ip" {
  name                = "${var.dmz_prefix}-lb-pip"
  resource_group_name = var.resource_group
  location            = var.default_location
  allocation_method   = "Static"
  domain_name_label   = "adfsrgsazwap"

  tags = {
    environment = "development"
    area        = "DMZ"
    project     = "Adfs_Environment"
    Asset_type  = "Public IP"
  }
}

#Load balancer for the WAP Servers
resource "azurerm_lb" "dmz_lb" {
  name                = "${var.dmz_prefix}-lb"
  resource_group_name = var.resource_group
  location            = var.default_location

  frontend_ip_configuration {
    name                 = "${var.dmz_prefix}-lb-ipconf"
    public_ip_address_id = azurerm_public_ip.dmz_lb_public_ip.id
  }

  tags = {
    environment = "development"
    area        = "DMZ"
    project     = "Adfs_Environment"
    Asset_type  = "Load balancer"
  }

}

#Loadbalancer back end pool for the WAP servers 
resource "azurerm_lb_backend_address_pool" "dmz_lb_backend_pool" {
  name                = "${var.dmz_prefix}-lb-backend-pool"
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.dmz_lb.id
}

resource "azurerm_lb_probe" "wap_lb_probe" {
  resource_group_name = var.resource_group
  loadbalancer_id     = azurerm_lb.dmz_lb.id
  name                = "WAP-HTTP-Probe"
  port                = 80
}


resource "azurerm_lb_rule" "wap_lb_http_rule" {
  resource_group_name            = var.resource_group
  loadbalancer_id                = azurerm_lb.dmz_lb.id
  name                           = "WAP-HTTP-Rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.dmz_lb_backend_pool.id
  frontend_ip_configuration_name = "${var.dmz_prefix}-lb-ipconf"
  probe_id                       = azurerm_lb_probe.wap_lb_probe.id

}

#Network Interfaces for the WAP VM's
resource "azurerm_network_interface" "dmz_wap_vm_interface" {
  name                = "${var.dmz_prefix}-${var.wap_dmz_prefix}-${format("%02d", count.index + 1)}-int"
  resource_group_name = var.resource_group
  location            = var.default_location
  count               = var.wap_server_count


  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.dmz_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.dmz_subnet_address_space, count.index + 10)

  }

  tags = {
    environment = "development"
    area        = "DMZ"
    project     = "Adfs_Environment"
    Asset_type  = "Network Interface"

  }

}

#WAP VM's the number of these servers is maintained by the WAP Server count variable
resource "azurerm_windows_virtual_machine" "dmz_wap_vm" {
  name                     = "${var.dmz_prefix}-${var.wap_dmz_prefix}-${format("%02d", count.index + 1)}-vm"
  resource_group_name      = var.resource_group
  location                 = var.default_location
  size                     = "Standard_B2s"
  admin_username           = "sysadmin"
  admin_password           = var.admin_password
  availability_set_id      = var.dmz_availability_set_id
  count                    = var.wap_server_count
  provision_vm_agent       = true
  enable_automatic_updates = true

  network_interface_ids = [
    azurerm_network_interface.dmz_wap_vm_interface[count.index].id
  ]

  tags = {
    environment = "development"
    area        = "DMZ"
    project     = "Adfs_Environment"
    Asset_type  = "VM"

  }

  os_disk {
    name                 = "${var.dmz_prefix}-${var.wap_dmz_prefix}-${format("%02d", count.index + 1)}-vm-disk"
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

#adding servers to the WAP Laod Balancer backend pool
resource "azurerm_network_interface_backend_address_pool_association" "wap_backendpool" {
  network_interface_id    = azurerm_network_interface.dmz_wap_vm_interface[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.dmz_lb_backend_pool.id
  count                   = var.wap_server_count

}



resource "azurerm_virtual_machine_extension" "vm_ext" {
  name                 = "Install_IIS_WAPProxy"
  virtual_machine_id   = azurerm_windows_virtual_machine.dmz_wap_vm[count.index].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  count                = var.wap_server_count

  settings = <<SETTINGS
  {
      "fileUris" : ["https://raw.githubusercontent.com/RobinSnelson/azuredevelopment/master/snippets/installwebapplicationproxyserver.ps1"],
      "commandToExecute" : "start powershell -executionpolicy Unrestricted -file installwebapplicationproxyserver.ps1"
  }
  SETTINGS

}