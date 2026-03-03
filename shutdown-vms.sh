#!/usr/bin/env bash
# Shutdown (deallocate) all VMs in the Terraform-managed resource group.
# Deallocating stops the VM and releases compute resources - you stop paying for VM hours.

set -e

# Ensure Azure CLI is logged in
if ! az account show &>/dev/null; then
  echo "Error: Not logged in to Azure. Run 'az login' first."
  exit 1
fi

RESOURCE_GROUP="${1:-$(cd "$(dirname "$0")" && terraform output -raw resource_group_name 2>/dev/null)}"

if [[ -z "$RESOURCE_GROUP" ]]; then
  echo "Usage: $0 [resource_group_name]"
  echo ""
  echo "Either run from the terraform directory, or pass the resource group name:"
  echo "  $0 license-server-prod-app-rg"
  exit 1
fi

echo "Deallocating VMs in resource group: $RESOURCE_GROUP"
echo ""

VMS=$(az vm list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null)

if [[ -z "$VMS" ]]; then
  echo "No VMs found in $RESOURCE_GROUP"
  exit 0
fi

for VM in $VMS; do
  echo "Stopping $VM..."
  az vm deallocate --resource-group "$RESOURCE_GROUP" --name "$VM" --no-wait
done

echo ""
echo "Deallocation started (running in background). VMs will stop shortly."
echo "To start them again: terraform apply (or az vm start for each VM)"
