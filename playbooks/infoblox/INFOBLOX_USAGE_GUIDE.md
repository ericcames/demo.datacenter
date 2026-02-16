# Infoblox Setup Role - Complete Usage Guide

## Overview

This role automates the initial setup of Infoblox NIOS appliances in DC1, including:
1. Changing the default admin password
2. Creating a dedicated ansible service account
3. Creating an Infoblox credential in Ansible Automation Platform 2.6

## Prerequisites

### 1. Install Required Collections

```bash
ansible-galaxy collection install infoblox.nios_modules
ansible-galaxy collection install awx.awx
```

### 2. Install Python Dependencies

```bash
# On RHEL/CentOS
pip3 install infoblox-client --break-system-packages

# Or in virtual environment
python3 -m venv venv
source venv/bin/activate
pip install infoblox-client
```

### 3. Network Access

Ensure you have network connectivity to:
- Infoblox appliance (HTTPS port 443)
- AAP/AWX instance (HTTPS port 443)

## Quick Start

### Step 1: Create Vault File

```bash
# Create encrypted vault
ansible-vault create group_vars/all/vault.yml
```

Add these variables:
```yaml
---
vault_infoblox_admin_password: "NewSecurePassword123!"
vault_infoblox_ansible_password: "AnsibleServiceAcct123!"
vault_aap_password: "AAPAdminPassword123!"
```

### Step 2: Create Playbook

```yaml
---
- name: Setup Infoblox
  hosts: localhost
  connection: local
  
  vars:
    infoblox_host: "infoblox.dc1.example.com"
    infoblox_admin_password: "{{ vault_infoblox_admin_password }}"
    infoblox_ansible_password: "{{ vault_infoblox_ansible_password }}"
    
    aap_host: "https://aap.dc1.example.com"
    aap_username: "admin"
    aap_password: "{{ vault_aap_password }}"
  
  roles:
    - infoblox_setup
```

### Step 3: Run Playbook

```bash
ansible-playbook infoblox_setup.yml --ask-vault-pass
```

## Configuration Options

### Minimal Configuration

```yaml
# Just change admin password, skip everything else
- hosts: localhost
  vars:
    infoblox_host: "infoblox.dc1.example.com"
    infoblox_admin_password: "{{ vault_infoblox_admin_password }}"
    infoblox_skip_user_creation: true
    infoblox_skip_aap_credential: true
  roles:
    - infoblox_setup
```

### Only Create AAP Credential

```yaml
# Skip Infoblox changes, only setup AAP
- hosts: localhost
  vars:
    infoblox_host: "infoblox.dc1.example.com"
    infoblox_skip_password_change: true
    infoblox_skip_user_creation: true
    
    aap_host: "https://aap.dc1.example.com"
    aap_username: "admin"
    aap_password: "{{ vault_aap_password }}"
    aap_infoblox_username: "ansible"
    aap_infoblox_password: "{{ vault_infoblox_ansible_password }}"
  roles:
    - infoblox_setup
```

### Custom Configuration

```yaml
- hosts: localhost
  vars:
    # Custom Infoblox settings
    infoblox_host: "10.0.1.100"
    infoblox_wapi_version: "2.11"  # Older NIOS version
    infoblox_validate_certs: true  # Enable SSL validation
    
    # Custom service account
    infoblox_ansible_username: "automation"
    infoblox_ansible_email: "automation@company.com"
    
    # Custom AAP settings
    aap_host: "https://tower.dc1.example.com"
    aap_infoblox_credential_name: "Production Infoblox"
    aap_infoblox_organization: "Network Team"
  roles:
    - infoblox_setup
```

## Use Cases

### Use Case 1: Initial DC1 Setup

Brand new Infoblox appliance with default credentials:

```yaml
---
- name: Initial Infoblox Setup for DC1
  hosts: localhost
  connection: local
  
  vars:
    # Infoblox details
    infoblox_host: "infoblox.dc1.example.com"
    infoblox_initial_admin_password: "infoblox"  # Default
    infoblox_admin_password: "{{ vault_infoblox_admin_password }}"
    
    # Create automation account
    infoblox_create_ansible_user: true
    infoblox_ansible_password: "{{ vault_infoblox_ansible_password }}"
    
    # Setup AAP integration
    aap_host: "https://aap.dc1.example.com"
    aap_password: "{{ vault_aap_password }}"
  
  roles:
    - infoblox_setup
```

Run with:
```bash
ansible-playbook dc1_infoblox_setup.yml --ask-vault-pass
```

### Use Case 2: Password Rotation

Change passwords on existing Infoblox:

```yaml
---
- name: Rotate Infoblox Passwords
  hosts: localhost
  connection: local
  
  vars:
    infoblox_host: "infoblox.dc1.example.com"
    infoblox_initial_admin_password: "{{ vault_old_admin_password }}"
    infoblox_admin_password: "{{ vault_new_admin_password }}"
    infoblox_ansible_password: "{{ vault_new_ansible_password }}"
    
    # Update AAP credential with new password
    aap_host: "https://aap.dc1.example.com"
    aap_password: "{{ vault_aap_password }}"
  
  roles:
    - infoblox_setup
```

### Use Case 3: Multi-Site Deployment

Setup multiple Infoblox appliances:

**inventory.yml:**
```yaml
all:
  children:
    infoblox_servers:
      hosts:
        infoblox_dc1:
          infoblox_host: "infoblox.dc1.example.com"
        infoblox_dc2:
          infoblox_host: "infoblox.dc2.example.com"
```

**playbook.yml:**
```yaml
---
- name: Setup All Infoblox Appliances
  hosts: infoblox_servers
  connection: local
  serial: 1  # One at a time
  
  vars:
    infoblox_admin_password: "{{ vault_infoblox_admin_password }}"
    infoblox_ansible_password: "{{ vault_infoblox_ansible_password }}"
    aap_host: "https://aap.dc1.example.com"
    aap_password: "{{ vault_aap_password }}"
    aap_infoblox_credential_name: "{{ inventory_hostname | upper }} Infoblox"
  
  roles:
    - infoblox_setup
```

## Verification

### Verify Infoblox Configuration

#### Test Admin Credentials

```bash
# Using curl
curl -k -u admin:NewPassword \
  https://infoblox.dc1.example.com/wapi/v2.12/network

# Using Ansible
ansible localhost -m uri -a "
  url=https://infoblox.dc1.example.com/wapi/v2.12/network
  user=admin
  password=NewPassword
  force_basic_auth=yes
  validate_certs=no
"
```

#### Test Ansible User

```bash
curl -k -u ansible:AnsiblePassword \
  https://infoblox.dc1.example.com/wapi/v2.12/network
```

#### Verify via Web UI

1. Open https://infoblox.dc1.example.com
2. Login as `admin` with new password
3. Navigate to Administration → Administrators
4. Verify `ansible` user exists

### Verify AAP Credential

#### Via AAP Web UI

1. Login to AAP: https://aap.dc1.example.com
2. Navigate to Resources → Credentials
3. Find "DC1 Infoblox" credential
4. Verify details are correct

#### Via awx CLI

```bash
# Install awx CLI
pip3 install awxkit

# List credentials
awx credentials list --name "DC1 Infoblox"

# Get credential details
awx credentials get <ID>
```

#### Via API

```bash
curl -k -u admin:password \
  https://aap.dc1.example.com/api/v2/credentials/ \
  | jq '.results[] | select(.name=="DC1 Infoblox")'
```

#### Test in Job Template

Create test job template in AAP:

```yaml
---
- name: Test Infoblox Credential
  hosts: localhost
  connection: local
  
  tasks:
    - name: Query Infoblox networks
      infoblox.nios_modules.nios_network_view:
        name: default
        state: present
        provider:
          host: "{{ lookup('env', 'INFOBLOX_HOST') }}"
          username: "{{ lookup('env', 'INFOBLOX_USERNAME') }}"
          password: "{{ lookup('env', 'INFOBLOX_PASSWORD') }}"
      
    - name: Display success
      ansible.builtin.debug:
        msg: "Infoblox credential works!"
```

Run the job template - it should succeed if credential is configured correctly.

## Troubleshooting

### Issue: Cannot connect to Infoblox

**Error:** `Connection timeout` or `Connection refused`

**Solutions:**
1. Verify network connectivity:
   ```bash
   ping infoblox.dc1.example.com
   curl -I https://infoblox.dc1.example.com
   ```

2. Check firewall rules:
   ```bash
   # From Ansible control node
   telnet infoblox.dc1.example.com 443
   ```

3. Verify DNS resolution:
   ```bash
   nslookup infoblox.dc1.example.com
   ```

### Issue: Authentication failed (401)

**Error:** `401 Unauthorized`

**Solutions:**
1. Verify credentials in vault:
   ```bash
   ansible-vault view group_vars/all/vault.yml
   ```

2. Check if password was already changed:
   ```bash
   # Try with new password
   curl -k -u admin:NewPassword \
     https://infoblox.dc1.example.com/wapi/v2.12/network
   ```

3. Reset password via Infoblox console if needed

### Issue: WAPI version mismatch

**Error:** `404 Not Found` on WAPI endpoint

**Solutions:**
1. Check NIOS version:
   - Login to Infoblox web UI
   - Check System → General Properties

2. Find correct WAPI version:
   ```bash
   curl -k https://infoblox.dc1.example.com/wapi/
   # Returns supported versions
   ```

3. Update variable:
   ```yaml
   infoblox_wapi_version: "2.11"  # or whatever is supported
   ```

### Issue: AAP credential creation fails

**Error:** `Organization 'Default' not found`

**Solutions:**
1. List available organizations:
   ```bash
   curl -k -u admin:password \
     https://aap.dc1.example.com/api/v2/organizations/
   ```

2. Use correct organization name:
   ```yaml
   aap_infoblox_organization: "YourOrgName"
   ```

### Issue: Admin user already has new password

**Error:** Initial authentication fails

**Solutions:**
1. Update initial password variable:
   ```yaml
   infoblox_initial_admin_password: "{{ vault_current_admin_password }}"
   ```

2. Or skip password change:
   ```yaml
   infoblox_skip_password_change: true
   ```

### Issue: Ansible user already exists

**Error:** User creation fails

**Solutions:**
The role handles this gracefully - it will update the existing user. If you want to skip:

```yaml
infoblox_skip_user_creation: true
```

## Integration with DC1 Infrastructure

### Directory Structure

```
demo.datacenter/
├── roles/
│   └── infoblox_setup/
├── playbooks/
│   └── setup_infoblox.yml
├── inventory/
│   └── dc1.ini
└── group_vars/
    ├── all/
    │   └── vault.yml (encrypted)
    └── infoblox_servers.yml
```

### Main Playbook Integration

```yaml
# playbooks/setup_dc1.yml
---
- name: Setup DC1 Infrastructure
  hosts: localhost
  connection: local
  
  roles:
    # Network infrastructure
    - role: infoblox_setup
      tags: [infoblox, network]
    
    # Other roles...
    - role: satellite_rhc_management
      tags: [satellite]
```

Run specific parts:
```bash
# Only Infoblox setup
ansible-playbook playbooks/setup_dc1.yml --tags infoblox

# Full DC1 setup
ansible-playbook playbooks/setup_dc1.yml
```

## Security Best Practices

1. **Always use Ansible Vault** for passwords
2. **Rotate passwords regularly** (90 days recommended)
3. **Use dedicated service accounts** (don't use admin for automation)
4. **Enable SSL certificate validation** in production
5. **Limit network access** to Infoblox management interface
6. **Audit AAP credential usage** regularly
7. **Use strong passwords** (16+ characters, mixed case, numbers, symbols)

## Next Steps After Setup

1. **Configure Infoblox Networks**
   - Define networks and subnets
   - Setup DHCP ranges
   - Configure DNS zones

2. **Create AAP Job Templates**
   - DNS record management
   - DHCP reservation automation
   - IP address allocation

3. **Setup Inventory Sources**
   - Configure Infoblox as inventory source
   - Sync network inventory to AAP

4. **Create Workflows**
   - Automated network provisioning
   - DNS/DHCP integration with VM creation
   - Network documentation automation

## Additional Resources

- [Infoblox NIOS Modules Documentation](https://docs.ansible.com/ansible/latest/collections/infoblox/nios_modules/)
- [AWX/AAP Credentials Guide](https://docs.ansible.com/ansible-tower/latest/html/userguide/credentials.html)
- [Infoblox WAPI Documentation](https://docs.infoblox.com/display/NAG8/Infoblox+WAPI+Documentation)
- [Ansible Vault Guide](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
