#######################################################################
##
##  Initialization and provider
##

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}


#######################################################################
##
##  Create resource group
##

resource "azurerm_resource_group" "rg" {
  name = "${var.prefix}-${var.environment}-rg"
  location = var.region
  tags = {
    "project" = var.project
    "environment" = var.environment
  }
}


#######################################################################
##
##  Networking setup
##


resource "azurerm_virtual_network" "vnet" {
  name = "${var.prefix}-${var.environment}-vnet"
  location = azurerm_resource_group.rg.location
  address_space = [
    var.address_space]
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    "project" = var.project
    "environment" = var.environment
  }
}

resource "azurerm_subnet" "subnet" {
  name = "${var.prefix}-${var.environment}-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name = azurerm_resource_group.rg.name
  address_prefixes = [var.address_space_subnet]
}

resource "azurerm_network_security_group" "anscn_nsg" {
  name = "${var.prefix}-${var.environment}-nsg"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    "project" = var.project
    "environment" = var.environment
  }
  security_rule {
    name = "SSH"
    priority = 102
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "22"
    source_address_prefix = var.source_network
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "anscn_pip" {
  name = "${var.prefix}-${var.environment}-ip"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method = "Dynamic"
  domain_name_label = var.vm_dns_hostname
  tags = {
    "project" = var.project
    "environment" = var.environment
  }
}

resource "azurerm_network_interface" "anscn_nic" {
  name = "${var.prefix}-${var.environment}-nic"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    "project" = var.project
    "environment" = var.environment
  }

  ip_configuration {
    name = "${var.prefix}-${var.environment}-ipconfig"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.anscn_pip.id
  }
}

resource "azurerm_subnet_network_security_group_association" "anscn_nsg_links" {
  subnet_id = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.anscn_nsg.id
}


#######################################################################
##
##  Virtual machine & setup
##

data "template_file" "linux-vm-cloud-init" {
  template = file("files/cloud-init.yaml")
  vars = {
    vm_dns_hostname = var.vm_dns_hostname
  }
}

resource "azurerm_virtual_machine" "anscn_vm" {
  name = "${var.prefix}-${var.environment}-vm"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  vm_size = var.vm_size
  network_interface_ids = [azurerm_network_interface.anscn_nic.id]
  delete_os_disk_on_termination = "true"
  tags = {
    "project" = var.project
    "environment" = var.environment
  }

  storage_image_reference {
    publisher = var.image_publisher
    offer = var.image_offer
    sku = var.image_sku
    version = var.image_version
  }

  storage_os_disk {
    name = "${var.prefix}-${var.environment}-osdisk"
    managed_disk_type = "Standard_LRS"
    caching = "ReadWrite"
    create_option = "FromImage"
  }

  storage_data_disk {
    name = "${var.prefix}-${var.environment}-datadisk"
    managed_disk_type = "Standard_LRS"
    create_option = "Empty"
    lun = 0
    disk_size_gb = var.vm_data_disk_size
  }

  os_profile {
    computer_name = "${var.prefix}"
    admin_username = var.admin_username
    admin_password = var.admin_password
    custom_data = base64encode(data.template_file.linux-vm-cloud-init.rendered)
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = file(var.ssh_public_key)
    }
  }
}

output "connection_info" {
  value = "Connect using -->    ssh ${var.admin_username}@${var.vm_dns_hostname}.${var.region}.cloudapp.azure.com"
}