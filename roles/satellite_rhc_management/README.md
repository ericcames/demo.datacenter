# Ansible Role: satellite_rhc_management

A unified role for managing Red Hat Satellite server registration and unregistration to/from Red Hat CDN and Insights using the official `redhat.rhel_system_roles.rhc` system role.

This role uses tags to control whether to register (create) or unregister (remove) systems.

## Requirements

- RHEL 8, RHEL 9, or RHEL 10
- `redhat.rhel_system_roles` collection installed
- Valid Red Hat subscription (for registration)
- Network connectivity to Red Hat CDN

## Installation

```bash
# Install the required collection
ansible-galaxy collection install redhat.rhel_system_roles
```

## Role Tags

This role uses two primary tags to control behavior:

- **`create`** - Register system to Red Hat CDN and Insights
- **`remove`** - Unregister system from Red Hat CDN and Insights

## Role Variables

### Authentication (Required for registration)

**Method 1: Activation Key (Recommended)**
```yaml
rhc_auth_activation_key: "satellite-server-key"
rhc_organization: "1234567"
```

**Method 2: Username/Password (Use Ansible Vault)**
```yaml
rhc_auth_username: "{{ vault_rhc_username }}"
rhc_auth_password: "{{ vault_rhc_password }}"
rhc_organization: "1234567"
```

### Registration Settings (create tag)

```yaml
# Satellite repository configuration
rhc_enable_satellite_repos: true
rhc_satellite_version: "6.15"

# Custom repositories (alternative to automatic Satellite repos)
rhc_custom_repositories: []
#  - {name: "rhel-8-for-x86_64-baseos-rpms", state: enabled}

# Release lock
rhc_release_lock: ""  # e.g., "8.9"

# Insights configuration
rhc_insights_state: present
rhc_insights_autoupdate: true
rhc_insights_remediation: present
rhc_insights_display_name: "{{ ansible_fqdn }}"
rhc_insights_tags: {}

# Proxy configuration
rhc_proxy_hostname: ""
rhc_proxy_port: ""
rhc_proxy_scheme: "http"
rhc_proxy_username: ""
rhc_proxy_password: ""

# Satellite server URL (for registering to Satellite, not CDN)
rhc_satellite_url: ""

# Environments (for Satellite content views)
rhc_environments: []
```

### Unregistration Settings (remove tag)

```yaml
# No additional variables needed for unregistration
# The role will automatically handle cleanup
```

## Dependencies

- `redhat.rhel_system_roles.rhc` (from `redhat.rhel_system_roles` collection)

## Example Playbooks

### Register Satellite Server to Red Hat CDN

```yaml
---
- name: Register Satellite Server
  hosts: satellite_servers
  become: true
  
  vars:
    rhc_auth_activation_key: "satellite-prod-key"
    rhc_organization: "1234567"
    rhc_enable_satellite_repos: true
    rhc_satellite_version: "6.15"
  
  roles:
    - role: satellite_rhc_management
      tags: [create]
```

**Run registration only:**
```bash
ansible-playbook -i inventory.ini playbook.yml --tags create
```

### Unregister Satellite Server

```yaml
---
- name: Unregister Satellite Server
  hosts: satellite_servers
  become: true
  
  roles:
    - role: satellite_rhc_management
      tags: [remove]
```

**Run unregistration only:**
```bash
ansible-playbook -i inventory.ini playbook.yml --tags remove
```

### Single Playbook for Both Operations

```yaml
---
- name: Manage Satellite Registration
  hosts: satellite_servers
  become: true
  
  vars:
    # Registration variables
    rhc_auth_activation_key: "satellite-prod-key"
    rhc_organization: "1234567"
    rhc_enable_satellite_repos: true
  
  roles:
    - satellite_rhc_management
```

**Usage:**
```bash
# Register only
ansible-playbook playbook.yml --tags create

# Unregister only
ansible-playbook playbook.yml --tags remove

# Run both (re-register)
ansible-playbook playbook.yml --tags create,remove
```

### Complete Lifecycle Management

```yaml
---
- name: Complete Satellite Lifecycle
  hosts: satellite_servers
  become: true
  
  vars:
    rhc_auth_activation_key: "satellite-prod-key"
    rhc_organization: "1234567"
    rhc_enable_satellite_repos: true
    rhc_insights_display_name: "{{ inventory_hostname }}-prod"
    rhc_insights_tags:
      datacenter: dc1
      role: satellite
      environment: production
  
  pre_tasks:
    - name: Show operation
      ansible.builtin.debug:
        msg: "Will perform: {{ ansible_run_tags }}"
      tags: [always]
  
  roles:
    - satellite_rhc_management
  
  post_tasks:
    - name: Verify registration
      ansible.builtin.command: subscription-manager status
      register: status
      changed_when: false
      failed_when: false
      tags: [create]
    
    - name: Show status
      ansible.builtin.debug:
        msg: "{{ status.stdout_lines }}"
      when: status.stdout is defined
      tags: [create]
```

### With Corporate Proxy

```yaml
---
- name: Register Through Proxy
  hosts: satellite_servers
  become: true
  
  vars:
    rhc_auth_activation_key: "satellite-prod-key"
    rhc_organization: "1234567"
    rhc_enable_satellite_repos: true
    rhc_proxy_hostname: "proxy.dc1.example.com"
    rhc_proxy_port: "3128"
    rhc_proxy_username: "{{ vault_proxy_user }}"
    rhc_proxy_password: "{{ vault_proxy_password }}"
  
  roles:
    - role: satellite_rhc_management
      tags: [create]
```

## Tag Usage

### Basic Tag Usage

```bash
# Register system
ansible-playbook playbook.yml --tags create

# Unregister system
ansible-playbook playbook.yml --tags remove

# Run both (useful for forced re-registration)
ansible-playbook playbook.yml --tags "create,remove"

# Skip registration
ansible-playbook playbook.yml --skip-tags create

# Skip unregistration
ansible-playbook playbook.yml --skip-tags remove
```

### Advanced Tag Combinations

```bash
# List all available tags
ansible-playbook playbook.yml --list-tags

# Run specific tagged tasks
ansible-playbook playbook.yml --tags "create,verify"

# Run everything except removal
ansible-playbook playbook.yml --skip-tags remove
```

## Satellite Server Repositories

When `rhc_enable_satellite_repos: true`, automatically enables:

**RHEL 8:**
- rhel-8-for-x86_64-baseos-rpms
- rhel-8-for-x86_64-appstream-rpms
- satellite-6.15-for-rhel-8-x86_64-rpms
- satellite-maintenance-6.15-for-rhel-8-x86_64-rpms

**RHEL 9:**
- rhel-9-for-x86_64-baseos-rpms
- rhel-9-for-x86_64-appstream-rpms
- satellite-6.15-for-rhel-9-x86_64-rpms
- satellite-maintenance-6.15-for-rhel-9-x86_64-rpms

**RHEL 10:**
- rhel-10-for-x86_64-baseos-rpms
- rhel-10-for-x86_64-appstream-rpms
- satellite-6.15-for-rhel-10-x86_64-rpms
- satellite-maintenance-6.15-for-rhel-10-x86_64-rpms

## Verification

### After Registration (create tag)

```bash
# Check registration status
subscription-manager status

# View system identity
subscription-manager identity

# List enabled repositories
subscription-manager repos --list-enabled

# Verify Insights
insights-client --status

# Check remediation (RHEL 8.4+)
rhc status
```

### After Unregistration (remove tag)

```bash
# Verify unregistration (should fail)
subscription-manager identity
# Expected: "This system is not yet registered"

# Check Insights (should show not registered)
insights-client --status
```

## Common Workflows

### Initial Satellite Server Setup

```bash
# 1. Register to Red Hat CDN
ansible-playbook site.yml --tags create --limit satellite.example.com

# 2. Update system
ssh satellite.example.com 'sudo dnf update -y'

# 3. Install Satellite
# (handled by separate playbook)
```

### Forced Re-registration

```bash
# Unregister and re-register in one command
ansible-playbook site.yml --tags "remove,create"
```

### Decommissioning

```bash
# Unregister before destroying
ansible-playbook site.yml --tags remove --limit old-satellite.example.com
```

### Testing Registration

```bash
# Register test system
ansible-playbook site.yml --tags create --limit test-satellite.example.com

# Verify it works
# ...

# Clean up test
ansible-playbook site.yml --tags remove --limit test-satellite.example.com
```

## Integration with DC1 Infrastructure

### Directory Structure

```
demo.datacenter/
├── roles/
│   └── satellite_rhc_management/
├── playbooks/
│   └── manage_satellite_registration.yml
├── inventory/
│   └── dc1.ini
└── group_vars/
    └── satellite_servers.yml
```

### Example Integration Playbook

```yaml
# playbooks/setup_satellite.yml
---
- name: Setup Satellite Server
  hosts: satellite_servers
  become: true
  
  roles:
    # Register to Red Hat
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

# Skip registration
ansible-playbook playbooks/setup_satellite.yml --skip-tags create

# Decommission (unregister only)
ansible-playbook playbooks/setup_satellite.yml --tags remove
```

## Troubleshooting

### Registration Issues

```bash
# Check with verbose output
ansible-playbook playbook.yml --tags create -vvv

# Verify connectivity
curl -I https://subscription.rhsm.redhat.com

# Check credentials
# For activation keys: verify in Red Hat Customer Portal
# For username/password: test manual registration
```

### Unregistration Issues

```bash
# Force unregistration
subscription-manager unregister
subscription-manager clean

# Then run remove tag
ansible-playbook playbook.yml --tags remove
```

### Tag Not Working

```bash
# Verify tags are defined
ansible-playbook playbook.yml --list-tags

# Check tag syntax
ansible-playbook playbook.yml --tags "create" -vv
```

## Best Practices

1. **Use Tags Consistently**
   - Always use `create` for registration
   - Always use `remove` for unregistration
   - Document tag usage in your playbooks

2. **Test Before Production**
   - Test with `--tags create` first
   - Verify registration works
   - Then test `--tags remove`

3. **Idempotency**
   - Role is idempotent for both operations
   - Safe to run multiple times
   - Will skip if already in desired state

4. **Security**
   - Use Ansible Vault for credentials
   - Prefer activation keys
   - Never commit secrets

5. **Documentation**
   - Document which tags do what
   - Include examples in your playbooks
   - Keep README updated

## License

MIT

## Author Information

Created for DC1 Datacenter project - Unified Satellite registration management using Red Hat system roles with tags.
