output "public_ip_address" {
  description = "Public IP address of the VM - use this to SSH and access your Django app"
  value       = azurerm_public_ip.django.ip_address
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.django.ip_address}"
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.django.name
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.django.name
}
