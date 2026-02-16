# Complete Usage Guide: Satellite RHC Management with Tags

This guide shows how to use the `satellite_rhc_management` role with the `create` and `remove` tags for unified registration management.

**Supported RHEL Versions:** RHEL 8, RHEL 9, and RHEL 10

## Quick Reference

```bash
# Register system
ansible-playbook playbook.yml --tags create

# Unregister system  
ansible-playbook playbook.yml --tags remove

# Force re-registration (unregister + register)
ansible-playbook playbook.yml --tags "remove,create"
```

## Installation

### 1. Install Red Hat System Roles Collection

```bash
ansible-galaxy collection install redhat.rhel_system_roles
```

### 2. Copy Role to Project

```bash
cp -r satellite_rhc_management /path/to/demo.datacenter/roles/
```

### 3. Verify Installation

```bash
ansible-galaxy collection list | grep rhel_system_roles
ls -la roles/satellite_rhc_management/
```

## Tag-Based Operations

### Understanding Tags

The role uses two main tags:

- **`create`** - Register system to Red Hat CDN and Insights
- **`remove`** - Unregister system from Red Hat CDN and Insights

Tags are specified with `--tags` or `--skip-tags` flags.

### Basic Tag Usage

#### Register System (create)

```bash
ansible-playbook -i inventory.ini playbook.yml --tags create
```

What it does:
- Validates authentication credentials
- Registers to Red Hat Subscription Management
- Enables specified repositories
- Connects to Red Hat Insights
- Configures remediation (if enabled)

#### Unregister System (remove)

```bash
ansible-playbook -i inventory.ini playbook.yml --tags remove
```

What it does:
- Checks current registration status
- Unregisters from Red Hat Subscription Management
- Disconnects from Red Hat Insights
- Cleans local subscription data

#### Force Re-registration

```bash
ansible-playbook -i inventory.ini playbook.yml --tags "remove,create"
```

Use when:
- Registration is in a bad state
- Changing activation keys
- Fixing repository issues
- Testing registration process

### Advanced Tag Usage

#### Skip Operations

```bash
# Run playbook but skip registration
ansible-playbook playbook.yml --skip-tags create

# Run playbook but skip unregistration
ansible-playbook playbook.yml --skip-tags remove
```

#### Check Mode (Dry Run)

```bash
# See what would happen (registration)
ansible-playbook playbook.yml --tags create --check

# See what would happen (unregistration)
ansible-playbook playbook.yml --tags remove --check
```

#### Verbose Output

```bash
# Debug registration issues
ansible-playbook playbook.yml --tags create -vvv

# Debug unregistration issues
ansible-playbook playbook.yml --tags remove -vvv
```

#### List Available Tags

```bash
ansible-playbook playbook.yml --list-tags
```

Output:
```
playbook: playbook.yml

  play #1 (satellite_servers): Manage Satellite Server Registration	TAGS: []
      TASK TAGS: [always, create, remove]
```

## Configuration Examples

### 1. Basic Registration with Activation Key

**group_vars/satellite_servers.yml:**
```yaml
---
rhc_auth_activation_key: "satellite-prod"
rhc_organization: "1234567"
rhc_enable_satellite_repos: true
```

**Usage:**
```bash
ansible-playbook site.yml --tags create
```

### 2. Registration with Username/Password (Vaulted)

**group_vars/satellite_servers/vault.yml (encrypted):**
```yaml
---
vault_rhc_username: "your-username"
vault_rhc_password: "your-password"
```

**group_vars/satellite_servers.yml:**
```yaml
---
rhc_auth_username: "{{ vault_rhc_username }}"
rhc_auth_password: "{{ vault_rhc_password }}"
rhc_organization: "1234567"
rhc_enable_satellite_repos: true
```

**Usage:**
```bash
ansible-playbook site.yml --tags create --ask-vault-pass
```

### 3. Registration with Custom Insights Tags

```yaml
---
rhc_auth_activation_key: "satellite-prod"
rhc_organization: "1234567"
rhc_enable_satellite_repos: true
rhc_insights_display_name: "{{ inventory_hostname }}-prod"
rhc_insights_tags:
  datacenter: dc1
  environment: production
  role: satellite
  compliance: sox
  backup: enabled
  owner: team-platform
```

### 4. Registration Through Corporate Proxy

```yaml
---
rhc_auth_activation_key: "satellite-prod"
rhc_organization: "1234567"
rhc_enable_satellite_repos: true
rhc_proxy_hostname: "proxy.dc1.example.com"
rhc_proxy_port: "3128"
rhc_proxy_username: "{{ vault_proxy_user }}"
rhc_proxy_password: "{{ vault_proxy_password }}"
```

### 5. Custom Repository Configuration

```yaml
---
rhc_auth_activation_key: "satellite-prod"
rhc_organization: "1234567"
rhc_enable_satellite_repos: false  # Don't use automatic repos
rhc_custom_repositories:
  - name: "rhel-8-for-x86_64-baseos-rpms"
    state: enabled
  - name: "rhel-8-for-x86_64-appstream-rpms"
    state: enabled
  - name: "satellite-6.15-for-rhel-8-x86_64-rpms"
    state: enabled
  - name: "satellite-maintenance-6.15-for-rhel-8-x86_64-rpms"
    state: enabled
  - name: "ansible-automation-platform-2.4-for-rhel-8-x86_64-rpms"
    state: enabled
```

## Real-World Workflows

### Workflow 1: Initial Satellite Server Setup

```bash
# Step 1: Register to Red Hat
ansible-playbook site.yml --tags create --limit satellite.dc1.example.com

# Step 2: Update system (separate playbook or manual)
ssh satellite.dc1.example.com 'sudo dnf update -y && sudo reboot'

# Step 3: Install Satellite (separate playbook)
ansible-playbook install_satellite.yml --limit satellite.dc1.example.com

# Step 4: Configure Satellite (separate playbook)
ansible-playbook configure_satellite.yml --limit satellite.dc1.example.com
```

### Workflow 2: Testing Registration Configuration

```bash
# Register test system
ansible-playbook site.yml --tags create --limit test-satellite.example.com

# Verify it works
ansible test-satellite.example.com -m command -a "subscription-manager status"

# If issues, force re-register
ansible-playbook site.yml --tags "remove,create" --limit test-satellite.example.com

# When satisfied, clean up
ansible-playbook site.yml --tags remove --limit test-satellite.example.com
```

### Workflow 3: Decommissioning Satellite Server

```bash
# Step 1: Export configuration (if needed)
ansible-playbook backup_satellite.yml

# Step 2: Unregister from Red Hat
ansible-playbook site.yml --tags remove --limit old-satellite.example.com

# Step 3: Destroy infrastructure
terraform destroy
```

### Workflow 4: Changing Activation Keys

```bash
# Update activation key in group_vars
vim group_vars/satellite_servers.yml

# Force re-registration with new key
ansible-playbook site.yml --tags "remove,create"
```

### Workflow 5: Fixing Broken Registration

```bash
# Try normal re-registration first
ansible-playbook site.yml --tags "remove,create"

# If that fails, manually clean and retry
ansible satellite.example.com -b -m command -a "subscription-manager unregister"
ansible satellite.example.com -b -m command -a "subscription-manager clean"
ansible-playbook site.yml --tags create
```

## Integration with DC1 Infrastructure

### Directory Structure

```
demo.datacenter/
├── roles/
│   └── satellite_rhc_management/
│       ├── README.md
│       ├── defaults/main.yml
│       ├── tasks/
│       │   ├── main.yml
│       │   ├── register.yml
│       │   └── unregister.yml
│       ├── meta/main.yml
│       └── requirements.yml
├── playbooks/
│   ├── manage_satellite.yml
│   ├── setup_satellite.yml
│   └── decommission_satellite.yml
├── inventory/
│   └── dc1.ini
└── group_vars/
    ├── satellite_servers.yml
    └── satellite_servers/
        └── vault.yml
```

### Main Playbook Structure

**playbooks/setup_satellite.yml:**
```yaml
---
- name: Complete Satellite Setup
  hosts: satellite_servers
  become: true
  
  roles:
    # Register to Red Hat (create tag)
    - role: satellite_rhc_management
      tags: [register, create]
    
    # Update system
    - role: system_update
      tags: [update]
    
    # Install Satellite
    - role: satellite_install
      tags: [install]
    
    # Configure Satellite
    - role: satellite_configure
      tags: [configure]
```

**Usage:**
```bash
# Full setup
ansible-playbook playbooks/setup_satellite.yml

# Only registration
ansible-playbook playbooks/setup_satellite.yml --tags create

# Skip registration (if already registered)
ansible-playbook playbooks/setup_satellite.yml --skip-tags create

# Only install and configure (skip registration and updates)
ansible-playbook playbooks/setup_satellite.yml --tags "install,configure"
```

### Makefile for Common Operations

**Makefile:**
```makefile
.PHONY: register unregister reregister status

PLAYBOOK=playbooks/manage_satellite.yml
INVENTORY=inventory/dc1.ini

register:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --tags create

unregister:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --tags remove

reregister:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --tags "remove,create"

status:
	ansible satellite_servers -i $(INVENTORY) -m command -a "subscription-manager status"

insights:
	ansible satellite_servers -i $(INVENTORY) -m command -a "insights-client --status"
```

**Usage:**
```bash
make register
make unregister
make reregister
make status
```

## Verification and Troubleshooting

### Verify Registration (After create tag)

```bash
# Quick status check
ansible satellite_servers -m command -a "subscription-manager status"

# Detailed verification
ansible satellite_servers -m shell -a "
  echo '=== Subscription Status ===' &&
  subscription-manager status &&
  echo '=== System Identity ===' &&
  subscription-manager identity &&
  echo '=== Enabled Repos ===' &&
  subscription-manager repos --list-enabled | grep -E '^Repo ID:|^Repo Name:' &&
  echo '=== Insights Status ===' &&
  insights-client --status
"
```

### Verify Unregistration (After remove tag)

```bash
# Should fail (which is success for unregistration)
ansible satellite_servers -m command -a "subscription-manager identity"

# Check Insights
ansible satellite_servers -m command -a "insights-client --status"
```

### Common Issues and Solutions

#### Issue: Tag Not Working

**Symptom:**
```bash
ansible-playbook playbook.yml --tags create
# Nothing happens or wrong tasks run
```

**Solution:**
```bash
# Check tag syntax in role
grep -r "tags:" roles/satellite_rhc_management/tasks/

# Ensure tags are defined correctly
# tasks should have: tags: [create] or tags: [remove]

# Verify playbook includes role with proper tags
ansible-playbook playbook.yml --list-tags
```

#### Issue: Registration Fails

**Symptom:**
```
TASK [Register system] **** failed
Invalid credentials
```

**Solution:**
```bash
# Verify activation key exists
# Login to https://access.redhat.com
# Check: Subscriptions → Activation Keys

# Test credentials manually
subscription-manager register \
  --activationkey=your-key \
  --org=1234567

# If using username/password, verify
subscription-manager register \
  --username=your-username \
  --password=your-password \
  --org=1234567
```

#### Issue: Repositories Not Available

**Symptom:**
```
Repository 'satellite-6.15-for-rhel-8-x86_64-rpms' not found
```

**Solution:**
```bash
# List available repos
subscription-manager repos --list | grep satellite

# Check subscription includes Satellite
subscription-manager list --consumed

# Verify RHEL version matches
cat /etc/redhat-release

# Use correct version in config
rhc_satellite_version: "6.15"  # Must match available repos
```

#### Issue: Already Registered Error

**Symptom:**
```
This system is already registered
```

**Solution:**
```bash
# Use remove tag first, then create
ansible-playbook playbook.yml --tags "remove,create"

# Or force re-registration in playbook
rhc_force_register: true  # (if using custom logic)
```

#### Issue: Insights Connection Fails

**Symptom:**
```
insights-client --register failed
Connection timeout
```

**Solution:**
```bash
# Test Insights connectivity
curl -I https://cert-api.access.redhat.com/r/insights

# Check proxy settings if behind proxy
insights-client --test-connection

# Review Insights logs
tail -f /var/log/insights-client/insights-client.log

# Manually register
insights-client --register --display-name="test-system"
```

## Best Practices

### 1. Use Tags Consistently

```yaml
# Good - Explicit tags in role usage
roles:
  - role: satellite_rhc_management
    tags: [create]

# Also good - Tags in playbook, not role
- name: Register system
  import_role:
    name: satellite_rhc_management
  tags: [create]
```

### 2. Test in Development First

```bash
# Always test against dev/test first
ansible-playbook site.yml --tags create --limit dev-satellite.example.com

# Verify
ansible dev-satellite.example.com -m command -a "subscription-manager status"

# Then production
ansible-playbook site.yml --tags create --limit prod-satellite.example.com
```

### 3. Document Tag Usage

```yaml
# At top of playbook
# TAGS:
#   create - Register system to Red Hat CDN
#   remove - Unregister system from Red Hat CDN
#   install - Install Satellite packages
#   configure - Configure Satellite

- name: My Playbook
  hosts: all
  roles:
    - role: satellite_rhc_management
      tags: [create, remove]
```

### 4. Use Check Mode for Validation

```bash
# See what would happen without making changes
ansible-playbook site.yml --tags create --check

# Combine with diff for detailed changes
ansible-playbook site.yml --tags create --check --diff
```

### 5. Implement Idempotency Checks

```yaml
pre_tasks:
  - name: Check if already registered
    command: subscription-manager identity
    register: reg_status
    changed_when: false
    failed_when: false
    tags: [always]
  
  - name: Skip if already registered (unless force)
    meta: end_host
    when:
      - reg_status.rc == 0
      - not force_reregister | default(false)
    tags: [create]
```

## Security Recommendations

1. **Always Use Ansible Vault**
```bash
ansible-vault encrypt_string 'your-password' --name 'vault_rhc_password'
```

2. **Limit Activation Key Scope**
- Create separate keys for different purposes
- Limit repository access per key
- Rotate keys regularly

3. **Use Service Accounts**
- Don't use personal Red Hat accounts
- Create dedicated automation account
- Limit permissions

4. **Secure Vault Password**
```bash
# Use password file (secure it properly)
echo "vault_password" > .vault_pass
chmod 600 .vault_pass
ansible-playbook site.yml --vault-password-file .vault_pass --tags create
```

5. **Audit Registration Activity**
```bash
# Check who registered what
ansible all -m command -a "subscription-manager identity"

# Review Insights activity
# Check https://console.redhat.com/insights
```

## Additional Resources

- [Red Hat System Roles - RHC](https://github.com/linux-system-roles/rhc)
- [Ansible Tags Documentation](https://docs.ansible.com/ansible/latest/user_guide/playbooks_tags.html)
- [Red Hat Subscription Management](https://access.redhat.com/documentation/en-us/red_hat_subscription_management/)
- [Red Hat Insights](https://access.redhat.com/products/red-hat-insights)
- [Satellite Installation Guide](https://access.redhat.com/documentation/en-us/red_hat_satellite/)
