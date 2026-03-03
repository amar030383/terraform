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
  description = "Name of the license server virtual machine"
  value       = azurerm_linux_virtual_machine.django.name
}

# --- Auctopus outputs ---

output "auctopus_public_ip_address" {
  description = "Public IP address of the Auctopus VM"
  value       = azurerm_public_ip.auctopus.ip_address
}

output "auctopus_ssh_command" {
  description = "SSH command to connect to the Auctopus VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.auctopus.ip_address}"
}

output "auctopus_vm_name" {
  description = "Name of the Auctopus virtual machine"
  value       = azurerm_linux_virtual_machine.auctopus.name
}
