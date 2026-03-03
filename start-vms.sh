#!/usr/bin/env bash
# Start all VMs in the Terraform-managed resource group.
# Use this after running shutdown-vms.sh to bring VMs back online.

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

echo "Starting VMs in resource group: $RESOURCE_GROUP"
echo ""

VMS=$(az vm list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null)

if [[ -z "$VMS" ]]; then
  echo "No VMs found in $RESOURCE_GROUP"
  exit 0
fi

for VM in $VMS; do
  echo "Starting $VM..."
  az vm start --resource-group "$RESOURCE_GROUP" --name "$VM" --no-wait
done

echo ""
echo "Start initiated (running in background). VMs will be ready shortly."
echo "Use 'terraform output' for SSH commands and public IPs."
