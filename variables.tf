variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "django-app-rg"
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "eastus"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "django-vm"
}

variable "vm_size" {
  description = "VM size - Standard_A1_v2: 1 vCPU, 2 GB RAM (use if Standard_B1ms unavailable in your region)"
  type        = string
  default     = "Standard_B1ms"
}

variable "admin_username" {
  description = "Admin username for SSH access"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key file (e.g., ~/.ssh/id_rsa.pub)"
  type        = string
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    environment = "production"
    application = "django"
  }
}
