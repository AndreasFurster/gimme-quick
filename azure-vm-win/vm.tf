# Add a Public IP address
resource "azurerm_public_ip" "vmip" {
  name                = "vm-ip"
  allocation_method   = "Static"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

output "public_ip" {
  value = azurerm_public_ip.vmip.ip_address
}

resource "local_file" "public_ip_file" {
    content  = azurerm_public_ip.vmip.ip_address
    filename = "./outputs/ip.txt"
}

module "module" {
    source  = "AndreasFurster/module/rdp"

    full_address = azurerm_public_ip.vmip.ip_address
    filename = "${path.module}/outputs/connect.rdp"
    username = "vmadmin"
}

# NIC with Public IP Address
resource "azurerm_network_interface" "nic" {
  name                = "vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "external"
    subnet_id                     = azurerm_subnet.vmsubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vmip.id
  }
}

resource "random_password" "vm_password" {
  length = 16
  special = true
}

resource "local_file" "vm_password_file" {
    content  = random_password.vm_password.result
    filename = "./outputs/vm_password.txt"
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_D2s_v3"

  admin_username        = "vmadmin"
  admin_password        = random_password.vm_password.result

  os_disk {
    name                 = "vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-10"
    sku       = "20h2-pro-g2"
    version   = "latest"
    
  }

  enable_automatic_updates = false
  provision_vm_agent       = true
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "automaticshutdown" {
  virtual_machine_id = azurerm_windows_virtual_machine.vm.id
  location           = var.location
  enabled            = true

  daily_recurrence_time = "0100"
  timezone              = "UTC"

  notification_settings {
    enabled         = false
  }
}
