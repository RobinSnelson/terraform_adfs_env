#Network Interfaces for the ADDS VM's
resource "azurerm_network_interface" "int_adds_vm_interface" {
  name                = "${var.internal_prefix}-${var.adds_internal_prefix}-${format("%02d", count.index + 1)}-int"
  resource_group_name = var.resource_group
  location            = var.default_location
  count               = var.adds_server_count


  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.internal_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.internal_subnet_address_space, count.index + 10)
  }

  tags = {
    environment = "development"
    area        = "Internal"
    project     = "Adfs_Environment"
    Asset_type  = "Network Interface"

  }

}

#ADDS VM's the number of these servers is maintained by the ADDS Server count variable
resource "azurerm_windows_virtual_machine" "int_adds_vm" {
  name                     = "${var.internal_prefix}-${var.adds_internal_prefix}-${format("%02d", count.index + 1)}-vm"
  resource_group_name      = var.resource_group
  location                 = var.default_location
  size                     = "Standard_B2s"
  admin_username           = "sysadmin"
  admin_password           = var.admin_password
  availability_set_id      = var.adds_availability_set_id
  count                    = var.adds_server_count
  provision_vm_agent       = true
  enable_automatic_updates = true

  tags = {
    environment = "development"
    area        = "Internal"
    project     = "Adfs_Environment"
    Asset_type  = "VM"

  }


  network_interface_ids = [
    azurerm_network_interface.int_adds_vm_interface[count.index].id
  ]

  os_disk {
    name                 = "${var.internal_prefix}-${var.adds_internal_prefix}-${format("%02d", count.index + 1)}-vm-disk"
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