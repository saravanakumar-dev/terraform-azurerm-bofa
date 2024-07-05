provider "azurerm" {
  features {} 
}

resource "azurerm_resource_group" "main" {
  name     = "test-resources"
  location = "eastus"
}

resource "azurerm_virtual_network" "main" {
  name                = "test-network"
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  name                = "test-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "test-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = "eastus"
  size                            = "Standard_DC4s_v3"
  admin_username                  = "adminuser"
  admin_password                  = "The$admin#password"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS" # local redundency
    caching              = "ReadWrite"
  }
  
}

resource "null_resource" "operation1"{

    provisioner "local-exec" {
    command = "cat ips.txt"
    on_failure = continue
    }
    provisioner "local-exec" {
    command = "echo ${azurerm_linux_virtual_machine.main.public_ip_address} > ips.txt"
    }
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.main.public_ip_address
}