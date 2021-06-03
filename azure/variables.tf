###################################################################################
##
##  Variables File
##  Here we store the default values for all the variables used in Terraform code
##


###################################################################################
##
##  Project
##

variable "project" {
  description = "This prefix will be included in the names resources."
  default = "ansible-control-node"
}

variable "environment" {
  description = "Project tier we are deploying currently i.e. (dev, test, prod)"
  default = "dev"
}

variable "prefix" {
  description = "This prefix will be included in the names resources."
  default = "ansiblecn"
}


###################################################################################
##
##  Azure general
##

variable "region" {
  description = "The region where the resources are created."
  default = "westeurope"
}

###################################################################################
##
##  Azure networks
##

variable "address_space" {
  description = "The address space that is used by the virtual network. You can supply more than one address space."
}

variable "address_space_subnet" {
  description = "The address prefix to use for the subnet."
}


###################################################################################
##
##  Azure storage account
##

variable "storage_account_tier" {
  description = "Defines the storage tier. Valid options are Standard and Premium."
  default = "Standard"
}

variable "storage_replication_type" {
  description = "Defines the replication type to use for this storage account. Valid options include LRS, GRS ZRS."
  default = "LRS"
}


###################################################################################
##
##  Azure virtual machines
##

variable "vm_size" {
  description = "Specifies the size of the virtual machine."
}

variable "vm_dns_hostname" {
  description = "Hostname under which server will be visible"
}

variable "vm_data_disk_size" {
  description = "The size in GB of disk mounted to VM."
}

variable "image_publisher" {
  description = "Name of the publisher of the image (az vm image list)"
  default = "Canonical"
}

variable "image_offer" {
  description = "Name of the offer (az vm image list)"
  default = "UbuntuServer"
}

variable "image_sku" {
  description = "Image SKU to apply (az vm image list)"
  default = "18.04-LTS"
}

variable "image_version" {
  description = "Version of the image to apply (az vm image list)"
  default = "latest"
}


###################################################################################
##
##  Access configs
##

variable "admin_username" {
  type = string
}

variable "admin_password" {
  type = string
  sensitive = true
}

variable "ssh_public_key" {
  type = string
  description = "file with public SSH key for vm access"
  sensitive = true
}

variable "source_network" {
  description = "Allow access from this network prefix."
  default = "*"
}
