# Azure VM for Django Application

Terraform configuration to provision an Azure VM for hosting a Django application.

## What Gets Created

| Resource | Purpose |
|----------|---------|
| Resource Group | Container for all resources |
| Virtual Network | 10.0.0.0/16 address space |
| Subnet | 10.0.1.0/24 |
| Network Security Group | Firewall rules |
| Public IP | Static IP for internet access |
| Network Interface | VM networking |
| Linux VM | Ubuntu 22.04 LTS |

**VM defaults:**
- **OS**: Ubuntu 22.04 LTS (Gen 2)
- **Ports open**: 22 (SSH), 80 (HTTP), 443 (HTTPS)
- **Static public IP** for consistent access

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

### 4. Connect to your VM

```bash
ssh azureuser@<public_ip_address>
```

Or use the SSH command from the Terraform output.

## Variables Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `ssh_public_key_path` | **Required.** Path to SSH public key | - |
| `resource_group_name` | Azure resource group name | `django-app-rg` |
| `location` | Azure region | `eastus` |
| `vm_name` | VM name | `django-vm` |
| `admin_username` | SSH username | `azureuser` |
| `vm_size` | VM size | `Standard_B1ms` |
| `os_disk_size_gb` | OS disk size (GB) | `30` |

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

## Deployment Stages (8 total)

1. Resource Group  
2. Virtual Network  
3. Subnet  
4. Network Security Group  
5. Public IP  
6. Network Interface  
7. NSG–NIC Association  
8. **Virtual Machine** ← Failures usually occur here (VM size/region)

## Next Steps: Deploying Django

Once connected via SSH:

1. Install Python, pip, and dependencies
2. Install and configure Nginx (reverse proxy for ports 80/443)
3. Install and configure Gunicorn/uWSGI
4. Set up SSL certificate (e.g. Let's Encrypt)
5. Deploy your Django application

## Cleanup

```bash
terraform destroy
```
