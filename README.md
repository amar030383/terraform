# Azure VMs for License Server & Auctopus Application

Terraform configuration to provision Azure VMs: a license server (Django) and an Auctopus application VM, each in its own subnet.

## What Gets Created

| Resource | Purpose |
|----------|---------|
| Resource Group | Container for all resources |
| Virtual Network | 10.0.0.0/16 address space (shared) |
| Subnet (license-server) | 10.0.1.0/24 |
| Subnet (auctopus) | 10.0.2.0/24 |
| NSG, Public IP, NIC, VM | Per-VM resources |

**License Server VM:**
- **OS**: Ubuntu 22.04 LTS (Gen 2)
- **Ports open**: 22 (SSH), 80 (HTTP), 443 (HTTPS), 6000 (Application)
- **Static public IP** for consistent access

**Auctopus VM:**
- **OS**: Ubuntu 22.04 LTS (Gen 2)
- **Size**: Standard_B2as_v2 (2 vCPU, 4 GiB RAM)
- **Ports open**: 22 (SSH), 443 (HTTPS), 8000, 5000 (Application)
- **Separate subnet** (10.0.2.0/24)

## Prerequisites

1. **Azure CLI** - [Install](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Terraform** - [Install](https://www.terraform.io/downloads)
3. **SSH key pair** - Generate with `ssh-keygen` if you don't have one

## Quick Start

### 1. Authenticate with Azure

```bash
az login
```

### 2. Configure variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set your SSH public key path (required):

```hcl
ssh_public_key_path = "~/.ssh/id_rsa.pub"
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Connect to your VMs

After `terraform apply`, use the outputs:

```bash
# License server
terraform output ssh_command

# Auctopus
terraform output auctopus_ssh_command
```

Or manually: `ssh azureuser@<public_ip_address>`

## How Terraform Manages Deployments (Without Breaking Existing Infra)

Terraform uses **state** to track every resource it creates. When you run `terraform apply`:

1. **State mapping** – Each resource has a unique address (e.g. `azurerm_linux_virtual_machine.django`, `azurerm_linux_virtual_machine.auctopus`). Terraform maps these to real Azure resource IDs in its state file.

2. **Incremental changes** – Terraform compares your config to the state and computes a **diff**. It only proposes changes for resources that differ. Unchanged resources are left as-is.

3. **Adding new resources** – When you add the Auctopus VM, Terraform sees new resources that don’t exist in state. It will **only create** those new resources. Existing resources (license-server VM, its subnet, NSG, etc.) are not modified or recreated.

4. **Changing existing resources** – If you change a property of an existing resource (e.g. VM size), Terraform will update or recreate only that resource. Other resources stay untouched.

5. **No cross-impact** – The license-server and auctopus resources are independent. Changing one does not affect the other.

**Summary:** Adding new resources = Terraform creates only the new ones. Existing infrastructure stays intact.

## Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `ssh_public_key_path` | **Required.** Path to SSH public key | - |
| `resource_group_name` | Azure resource group name | `django-app-rg` |
| `location` | Azure region | `eastus` |
| `vm_name` | License server VM name | `django-vm` |
| `admin_username` | SSH username | `azureuser` |
| `vm_size` | License server VM size | `Standard_B1ms` |
| `os_disk_size_gb` | License server OS disk (GB) | `30` |
| `auctopus_vm_name` | Auctopus VM name | `auctopus-vm` |
| `auctopus_vm_size` | Auctopus VM size | `Standard_B2as_v2` |
| `auctopus_os_disk_size_gb` | Auctopus OS disk (GB) | `30` |

## VM Size & Region Notes

**Capacity restrictions:** Some regions (e.g. `eastus`) may have capacity limits on certain VM sizes. If you see `SkuNotAvailable` errors:

1. **Try a different region** – e.g. `australiaeast`, `eastus2`, `westus2`, `centralus`
2. **Try a different VM size** – e.g. `Standard_B2ats_v2`, `Standard_B2s`, `Standard_D2s_v3`
3. **Destroy and recreate** when changing region:
   ```bash
   terraform destroy
   # Update location in terraform.tfvars
   terraform apply
   ```

**Recommended sizes (1–2 vCPU, 2–4 GB RAM):**

| Size | vCPU | RAM | Notes |
|------|------|-----|-------|
| `Standard_B1ms` | 1 | 2 GB | Burstable, cost-effective |
| `Standard_B2ats_v2` | 2 | 1 GiB | Australia East, low cost |
| `Standard_B2s` | 2 | 4 GB | Often better availability |
| `Standard_A1_v2` | 1 | 2 GB | Gen 1 image only |
| `Standard_D2s_v3` | 2 | 8 GB | General purpose, higher cost |

**Image compatibility:** `Standard_A1_v2` and other Gen 1-only sizes require the Gen 1 Ubuntu image (`22_04-lts`). Most B-series and D-series support Gen 2 (`22_04-lts-gen2`).

## Deployment Stages

**Shared:** Resource Group → Virtual Network → Subnets (license-server, auctopus)

**Per VM:** NSG → Public IP → Network Interface → NSG–NIC Association → Virtual Machine

Failures usually occur at the VM stage (VM size/region availability).

## Next Steps: Deploying Django

Once connected via SSH:

1. Install Python, pip, and dependencies
2. Install and configure Nginx (reverse proxy for ports 80/443)
3. Install and configure Gunicorn/uWSGI
4. Set up SSL certificate (e.g. Let's Encrypt)
5. Deploy your Django application

## Shutting Down VMs (Save Costs)

To deallocate all VMs (stops them and releases compute—you stop paying for VM hours):

```bash
./shutdown-vms.sh
```

Or pass the resource group explicitly:

```bash
./shutdown-vms.sh license-server-prod-app-rg
```

## Starting VMs

To start all VMs again after shutting them down:

```bash
./start-vms.sh
```

Or pass the resource group explicitly:

```bash
./start-vms.sh license-server-prod-app-rg
```

Both scripts require `az login` first.

## Cleanup

```bash
terraform destroy
```
