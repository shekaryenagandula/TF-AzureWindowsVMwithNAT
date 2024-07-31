locals {
  suffix = "aa-lab-03"
}
resource "azurerm_resource_group" "mainrg" {
  name = "rg-${local.suffix}"
  location = "centralindia"
}

resource "azurerm_virtual_network" "mainvnet" {
  name = "vnet${local.suffix}"
  location = azurerm_resource_group.mainrg.location
  resource_group_name = azurerm_resource_group.mainrg.name
  address_space = ["10.20.0.0/16"]
}

resource "azurerm_network_security_group" "mainnsg" {
  name                = "nsg-${local.suffix}"
  location            = azurerm_resource_group.mainrg.location
  resource_group_name = azurerm_resource_group.mainrg.name
}

resource "azurerm_subnet" "webappsubnet" {
  name                 = "webappsubnet"
  resource_group_name  = azurerm_resource_group.mainrg.name
  virtual_network_name = azurerm_virtual_network.mainvnet.name
  address_prefixes     = ["10.20.0.0/24"]
}

resource "azurerm_subnet" "bastionsubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.mainrg.name
  virtual_network_name = azurerm_virtual_network.mainvnet.name
  address_prefixes     = ["10.20.1.0/26"]
}


resource "azurerm_subnet_network_security_group_association" "nsgtowebapp" {
  subnet_id                 = azurerm_subnet.webappsubnet.id
  network_security_group_id = azurerm_network_security_group.mainnsg.id
}

#BastionResource
resource "azurerm_public_ip" "pipbastion" {
  name                = "pipbastion-${local.suffix}"
  location            = azurerm_resource_group.mainrg.location
  resource_group_name = azurerm_resource_group.mainrg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastionhost" {
  name                = "bastionhost-${local.suffix}"
  location            = azurerm_resource_group.mainrg.location
  resource_group_name = azurerm_resource_group.mainrg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastionsubnet.id
    public_ip_address_id = azurerm_public_ip.pipbastion.id
  }
}



#VirtualMachine
resource "azurerm_network_interface" "vmnic" {
  name                = "nic-${local.suffix}"
  location            = azurerm_resource_group.mainrg.location
  resource_group_name = azurerm_resource_group.mainrg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.webappsubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "windowsvm" {
  name                = "wvm-${local.suffix}"
  resource_group_name = azurerm_resource_group.mainrg.name
  location            = azurerm_resource_group.mainrg.location
  size                = "Standard_B2s"
  admin_username      = "azadmin"
  admin_password      = "Login@85208520"
  network_interface_ids = [
    azurerm_network_interface.vmnic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}