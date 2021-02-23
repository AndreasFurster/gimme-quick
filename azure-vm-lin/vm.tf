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

# DNS record for public IP
# resource "azurerm_dns_a_record" "dns_record" {
#   name                = "peer0.coolblue"
#   zone_name           = "sbc.andreasfurster.nl"
#   resource_group_name = azurerm_resource_group.rg.name
#   ttl                 = 1
#   records             = [azurerm_public_ip.vmip.ip_address]
# }

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

# resource "tls_private_key" "ssh" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# output "tls_private_key" { value = tls_private_key.ssh.private_key_pem }

# resource "local_file" "private_key" {
#     content  = tls_private_key.ssh.private_key_pem
#     filename = "./outputs/private_key.pem"
# }


resource "local_file" "connect" {
    content  = "ssh -o \"StrictHostKeyChecking no\" vmadmin@${azurerm_public_ip.vmip.ip_address}"
    filename = "./outputs/connect.sh"
}


resource "azurerm_linux_virtual_machine" "vm" {
  name                  = "vm"
  location              = var.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_D2s_v3"

  os_disk {
    name                 = "vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "vm"
  admin_username                  = "vmadmin"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "vmadmin"
    public_key = file("~/.ssh/id_rsa.pub")
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "automaticshutdown" {
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  location           = var.location
  enabled            = true

  daily_recurrence_time = "0100"
  timezone              = "UTC"

  notification_settings {
    enabled         = false
  }
}

# resource "null_resource" "dependancies" {
#   provisioner "file" {
#     source      = "./scripts/dependancies.sh"
#     destination = "~/dependancies.sh"
#   }
  
#   provisioner "remote-exec" {
#     inline = [
#       "chmod +x ~/dependancies.sh",
#       "~/dependancies.sh",
#     ]
#   }

#   connection {
#     type = "ssh"
#     user = azurerm_linux_virtual_machine.vm.admin_username
#     host = azurerm_public_ip.vmip.ip_address
#     private_key = tls_private_key.ssh.private_key_pem
#   }
# }