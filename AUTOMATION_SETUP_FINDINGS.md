# Auctopus Automation Setup - Findings & Fixes

## Summary

Ran the automation on `azureuser@20.213.152.139` (auctopus-vm, internal IP 10.0.2.4). Found **2 issues**; 1 fixed, 1 requires your action.

---

## Issue 1: SSH Permission Denied (FIXED)

**Error:** `automation@10.0.2.4: Permission denied (publickey)`

**Cause:** Azure Ubuntu cloud images set `PasswordAuthentication no` in `/etc/ssh/sshd_config.d/50-cloudimg-settings.conf` and `60-cloudimg-settings.conf`. Ansible uses `sshpass` with the automation user's password, which requires password auth to be enabled.

**Fix applied on the VM:**
```bash
# Create override that loads last (higher number = later)
sudo tee /etc/ssh/sshd_config.d/99-password-auth.conf << 'EOF'
KbdInteractiveAuthentication yes
PasswordAuthentication yes
EOF
sudo systemctl restart sshd
```

---

## Issue 2: GitHub Authentication Failed (ACTION REQUIRED)

**Error:** `remote: Invalid username or token. Password authentication is not supported for Git operations.`

**Cause:** The `GITHUB_TOKEN` is invalid, expired, or lacks `repo` scope. GitHub no longer accepts account passwords for Git operations; a valid Personal Access Token (PAT) is required.

**What you need to do:**
1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Create a new token with `repo` scope (and `read:org` if the repo is in an org)
3. Update your environment:
   ```bash
   export GITHUB_TOKEN='<your-new-valid-token>'
   ```
4. Re-run the ansible playbook

---

## Correct Command Sequence

```bash
# 1. Disable existing application (if any)
sudo systemctl stop auctopus_docker.service 2>/dev/null || true
sudo systemctl disable auctopus_docker.service 2>/dev/null || true
sudo rm -f /etc/systemd/system/auctopus_docker.service
sudo systemctl daemon-reload

# 2. Install packages (Docker needs official repo - containerd.io not in Ubuntu default)
sudo apt update && sudo apt install -y git ansible sshpass net-tools snmp curl
# Add Docker repo first, then: containerd.io docker-buildx-plugin docker-compose-plugin

# 3. Create automation user
sudo useradd -m -s /bin/bash automation
echo 'automation:automation' | sudo chpasswd
sudo usermod -aG sudo,docker automation
echo 'automation ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/automation

# 4. Enable SSH password auth (see Issue 1 fix above)

# 5. Clone automation repo
git clone https://github.com/auctopusGithub/automation.git
cd automation

# 6. Set env vars (use valid GITHUB_TOKEN!)
export GITHUB_TOKEN='<valid-pat>'
export DOCKER_TOKEN='7XpFEM8hVcxrP0ot'
export DEPLOYMENT_TYPE='development'
export SERVER_IP='10.0.2.4'
export ANSIBLE_SSH_HOST='10.0.2.4'
export SERVER_PORT='80'
export GITHUB_USERNAME='bhavinpatel-auctopus'
export DOCKER_USERNAME='auctopustechnologies'
export ANSIBLE_SSH_USER='automation'
export ANSIBLE_SSH_PASS='automation'
export ANSIBLE_BECOME_PASS='automation'
export AUCTOPUS_DOCKER_REPO_URL='https://github.com/auctopusGithub/auctopus_docker.git'
export SYSTEM_MANAGEMENT_REPO_URL='https://github.com/auctopusGithub/system_management.git'

# 7. Run playbook
ansible-playbook master_setup.yml -i inventory.yml --ssh-extra-args='-o StrictHostKeyChecking=no'
```

---

## Playbook Path Note

The user instructions said:
```bash
ansible-playbook automation/master_setup.yml -i automation/inventory.yml
```

That assumes you run from the **parent** of the `automation` directory. If you `cd` into `automation` first, use:
```bash
ansible-playbook master_setup.yml -i inventory.yml
```
