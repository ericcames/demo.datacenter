# Ansible Role: infoblox_setup

Configure Infoblox NIOS admin password and create Ansible Automation Platform 2.6 credentials for Infoblox integration.

## Description

This role performs two main functions:
1. Sets or updates the Infoblox admin password
2. Creates an Infoblox credential in Ansible Automation Platform 2.6 (AAP) for network automation

## Requirements

### Python Libraries
```bash
pip install infoblox-client --break-system-packages
```

### Ansible Collections
```bash
ansible-galaxy collection install infoblox.nios_modules
ansible-galaxy collection install awx.awx
```

### Access Requirements
- Infoblox NIOS with WAPI enabled
- Network connectivity to Infoblox appliance
- AAP 2.6 (or AWX) instance with API access
- Admin credentials for both systems

## Role Variables

### Infoblox Configuration

```yaml
# Infoblox connection details
infoblox_host: "infoblox.dc1.example.com"
infoblox_wapi_version: "2.12"  # NIOS WAPI version

# Initial admin credentials (for first login)
infoblox_initial_admin_username: "admin"
infoblox_initial_admin_password: "infoblox"  # Default password

# New admin password (use Ansible Vault)
infoblox_admin_password: "{{ vault_infoblox_admin_password }}"

# Validate SSL certificates
infoblox_validate_certs: false
```

### AAP Configuration

```yaml
# AAP/AWX connection details
aap_host: "https://aap.dc1.example.com"
aap_username: "admin"
aap_password: "{{ vault_aap_password }}"
aap_validate_certs: true

# Infoblox credential settings in AAP
aap_infoblox_credential_name: "DC1 Infoblox"
aap_infoblox_credential_description: "Infoblox NIOS credential for DC1"
aap_infoblox_organization: "Default"

# Infoblox credential details for AAP
aap_infoblox_username: "ansible"  # Service account for automation
aap_infoblox_password: "{{ vault_infoblox_ansible_password }}"
```

### Optional Variables

```yaml
# Create dedicated ansible user in Infoblox
infoblox_create_ansible_user: true
infoblox_ansible_username: "ansible"
infoblox_ansible_password: "{{ vault_infoblox_ansible_password }}"
infoblox_ansible_admin_group: "admin-group"

# Skip admin password change
infoblox_skip_password_change: false

# Skip AAP credential creation
infoblox_skip_aap_credential: false
```

## Dependencies

None

## Example Playbook

### Basic Usage

```yaml
---
- name: Setup Infoblox in DC1
  hosts: localhost
  connection: local
  
  vars:
    infoblox_host: "infoblox.dc1.example.com"
    infoblox_admin_password: "{{ vault_infoblox_admin_password }}"
    
    aap_host: "https://aap.dc1.example.com"
    aap_username: "admin"
    aap_password: "{{ vault_aap_password }}"
  
  roles:
    - infoblox_setup
```

### Complete Setup with Service Account

```yaml
---
- name: Complete Infoblox Setup
  hosts: localhost
  connection: local
  
  vars:
    # Infoblox settings
    infoblox_host: "infoblox.dc1.example.com"
    infoblox_initial_admin_password: "infoblox"
    infoblox_admin_password: "{{ vault_infoblox_admin_password }}"
    
    # Create dedicated automation user
    infoblox_create_ansible_user: true
    infoblox_ansible_username: "ansible"
    infoblox_ansible_password: "{{ vault_infoblox_ansible_password }}"
    
    # AAP settings
    aap_host: "https://aap.dc1.example.com"
    aap_username: "admin"
    aap_password: "{{ vault_aap_password }}"
    aap_infoblox_credential_name: "DC1 Infoblox"
    aap_infoblox_organization: "DC1 Operations"
  
  roles:
    - infoblox_setup
```

### Only Change Admin Password

```yaml
---
- name: Change Infoblox Admin Password
  hosts: localhost
  connection: local
  
  vars:
    infoblox_host: "infoblox.dc1.example.com"
    infoblox_admin_password: "{{ vault_infoblox_new_password }}"
    infoblox_skip_aap_credential: true
  
  roles:
    - infoblox_setup
```

### Only Create AAP Credential

```yaml
---
- name: Create AAP Infoblox Credential
  hosts: localhost
  connection: local
  
  vars:
    infoblox_host: "infoblox.dc1.example.com"
    infoblox_skip_password_change: true
    
    aap_host: "https://aap.dc1.example.com"
    aap_username: "admin"
    aap_password: "{{ vault_aap_password }}"
    aap_infoblox_username: "ansible"
    aap_infoblox_password: "{{ vault_infoblox_ansible_password }}"
  
  roles:
    - infoblox_setup
```

## Workflow

1. **Connect to Infoblox** using initial credentials
2. **Update admin password** if not skipped
3. **Create ansible service account** if requested
4. **Verify Infoblox connectivity** with new credentials
5. **Connect to AAP** using provided credentials
6. **Create Infoblox credential type** in AAP (if doesn't exist)
7. **Create Infoblox credential** in AAP with provided details
8. **Verify credential** can be used in AAP

## Security Best Practices

1. **Use Ansible Vault** for all passwords:
   ```bash
   ansible-vault encrypt_string 'your-password' --name 'vault_infoblox_admin_password'
   ```

2. **Create dedicated service account** for automation:
   ```yaml
   infoblox_create_ansible_user: true
   infoblox_ansible_username: "ansible"
   ```

3. **Use least privilege** - grant only necessary permissions

4. **Rotate passwords regularly**

5. **Enable SSL certificate validation** in production:
   ```yaml
   infoblox_validate_certs: true
   aap_validate_certs: true
   ```

## Verification

### Verify Infoblox Password Change

```bash
# Test new password
curl -k -u admin:new_password \
  https://infoblox.dc1.example.com/wapi/v2.12/network

# Or use Ansible
ansible localhost -m uri -a "
  url=https://infoblox.dc1.example.com/wapi/v2.12/network
  user=admin
  password=new_password
  force_basic_auth=yes
  validate_certs=no
"
```

### Verify AAP Credential

```bash
# Via awx CLI
awx credentials list --name "DC1 Infoblox"

# Via API
curl -k -u admin:password \
  https://aap.dc1.example.com/api/v2/credentials/ \
  | jq '.results[] | select(.name=="DC1 Infoblox")'
```

### Test in AAP Job Template

Create a test job template using the Infoblox credential:

```yaml
---
- name: Test Infoblox Credential
  hosts: localhost
  connection: local
  
  tasks:
    - name: Fetch Infoblox networks
      infoblox.nios_modules.nios_network:
        network: 192.168.1.0/24
        state: present
        provider:
          host: "{{ lookup('env', 'INFOBLOX_HOST') }}"
          username: "{{ lookup('env', 'INFOBLOX_USERNAME') }}"
          password: "{{ lookup('env', 'INFOBLOX_PASSWORD') }}"
```

## Troubleshooting

### Issue: Cannot connect to Infoblox

**Error:** `Connection refused` or `Timeout`

**Solutions:**
1. Check network connectivity
2. Verify WAPI is enabled in Infoblox
3. Check firewall rules
4. Verify correct hostname/IP

### Issue: Authentication failed

**Error:** `401 Unauthorized`

**Solutions:**
1. Verify username and password
2. Check if using default credentials for initial setup
3. Ensure password was changed successfully
4. Try password reset via Infoblox console

### Issue: AAP credential creation fails

**Error:** `404 Not Found` or `Organization not found`

**Solutions:**
1. Verify AAP/AWX is accessible
2. Check organization name is correct
3. Ensure admin user has permissions
4. Verify AAP API is enabled

### Issue: Infoblox user creation fails

**Error:** `Admin group not found`

**Solutions:**
1. Verify admin group exists in Infoblox
2. Check user doesn't already exist
3. Ensure sufficient permissions

## Variables for group_vars

Example `group_vars/infoblox_servers.yml`:

```yaml
---
# Infoblox connection
infoblox_host: "{{ inventory_hostname }}"
infoblox_wapi_version: "2.12"
infoblox_validate_certs: false

# Admin password (vaulted)
infoblox_admin_password: "{{ vault_infoblox_admin_password }}"

# Service account
infoblox_create_ansible_user: true
infoblox_ansible_username: "ansible"
infoblox_ansible_password: "{{ vault_infoblox_ansible_password }}"

# AAP integration
aap_host: "https://aap.dc1.example.com"
aap_username: "admin"
aap_password: "{{ vault_aap_password }}"
aap_infoblox_credential_name: "DC1 Infoblox - {{ inventory_hostname }}"
aap_infoblox_organization: "DC1 Operations"
```

## Integration with DC1

This role is designed to work with the DC1 datacenter setup:

```yaml
# In your DC1 setup playbook
- name: Configure Infoblox
  hosts: localhost
  connection: local
  
  roles:
    - infoblox_setup
  
  tags:
    - infoblox
    - network
    - ipam
```

## License

MIT

## Author Information

Created for DC1 Datacenter project - Infoblox integration with Ansible Automation Platform 2.6.
