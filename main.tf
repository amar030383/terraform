terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "django" {
  name     = var.resource_group_name
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "django" {
  name                = "${var.vm_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.django.location
  resource_group_name = azurerm_resource_group.django.name
}

# Subnet
resource "azurerm_subnet" "django" {
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = azurerm_resource_group.django.name
  virtual_network_name = azurerm_virtual_network.django.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Group - Allow SSH (22) and HTTPS (443)
resource "azurerm_network_security_group" "django" {
  name                = "${var.vm_name}-nsg"
  location            = azurerm_resource_group.django.location
  resource_group_name = azurerm_resource_group.django.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowApp6000"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IP
resource "azurerm_public_ip" "django" {
  name                = "${var.vm_name}-pip"
  location            = azurerm_resource_group.django.location
  resource_group_name = azurerm_resource_group.django.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface
resource "azurerm_network_interface" "django" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.django.location
  resource_group_name = azurerm_resource_group.django.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.django.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.django.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "django" {
  network_interface_id      = azurerm_network_interface.django.id
  network_security_group_id = azurerm_network_security_group.django.id
}

# Virtual Machine
# Standard_B1ms: 1 vCPU, 2 GB RAM - ideal for lightweight Django apps
resource "azurerm_linux_virtual_machine" "django" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.django.name
  location            = azurerm_resource_group.django.location
  size                = var.vm_size
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  network_interface_ids = [
    azurerm_network_interface.django.id,
  ]

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = var.tags
}
