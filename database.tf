variable "yamlconfiguration" {
  description = [for f in fileset("${path.module}/yamlconfiguration", "[^_]*.yaml") : yamldecode(file("${path.module}/yamlconfiguration/${f}"))]
  default     = "vm.yaml"
}

locals {
  yamlconfiguration_data = yamldecode(file(var.yamlconfiguration))
}

resource "azurerm_resource_group" "juliovm" {
  name     = "julio"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.juliovm.location
  resource_group_name = azurerm_resource_group.juliovm.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.juliovm.name
  virtual_network_name = azurerm_virtual_network.juliovm.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "juliovm" {
  count               = length(local.vm_config_data.vms)
  name                = "${local.vm_config_data.vms[count.index].name}-nic"
  location            = azurerm_resource_group.juliovm.location
  resource_group_name = azurerm_resource_group.juliovm.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "example" {
  count                = length(local.vm_config_data.vms)
  name                 = local.vm_config_data.vms[count.index].name
  location             = azurerm_resource_group.juliovm.location
  resource_group_name  = azurerm_resource_group.juliovm.name
  network_interface_ids = [element(azurerm_network_interface.example[*].id, count.index)]

  vm_size              = local.vm_config_data.vms[count.index].vm_size

  storage_os_disk {
    name              = "${local.vm_config_data.vms[count.index].name}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = local.vm_config_data.vms[count.index].name
    admin_username = "adminuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/adminuser/.ssh/authorized_keys"
      key_data = "ssh-rsa <YOUR_SSH_PUBLIC_KEY>"
    }
  }
}
