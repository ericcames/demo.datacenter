# RHEL 10 Support Guide

## Overview

The `satellite_rhc_management` role now fully supports RHEL 10 in addition to RHEL 8 and 9.

## RHEL 10 Repositories

When registering a RHEL 10 system with `rhc_enable_satellite_repos: true`, the following repositories are automatically enabled:

```yaml
- rhel-10-for-x86_64-baseos-rpms
- rhel-10-for-x86_64-appstream-rpms
- satellite-6.15-for-rhel-10-x86_64-rpms
- satellite-maintenance-6.15-for-rhel-10-x86_64-rpms
```

## Quick Start - RHEL 10

### Register RHEL 10 Satellite Server

```bash
# 1. Ensure RHEL 10 system
cat /etc/redhat-release
# Expected: Red Hat Enterprise Linux release 10.0 (or similar)

# 2. Create playbook
cat > register_rhel10.yml << 'EOF'
---
- hosts: satellite_servers
  become: true
  vars:
    rhc_auth_activation_key: "satellite-rhel10-key"
    rhc_organization: "1234567"
    rhc_enable_satellite_repos: true
    rhc_satellite_version: "6.15"
  roles:
    - role: satellite_rhc_management
      tags: [create]
EOF

# 3. Register
ansible-playbook register_rhel10.yml --tags create
```

### Verify RHEL 10 Registration

```bash
# Check enabled repositories
subscription-manager repos --list-enabled | grep rhel-10

# Expected output should include:
# Repo ID:   rhel-10-for-x86_64-baseos-rpms
# Repo ID:   rhel-10-for-x86_64-appstream-rpms
# Repo ID:   satellite-6.15-for-rhel-10-x86_64-rpms
# Repo ID:   satellite-maintenance-6.15-for-rhel-10-x86_64-rpms
```

## Configuration Example - RHEL 10

### group_vars/rhel10_satellites.yml

```yaml
---
# RHEL 10 Satellite Server Configuration

# Authentication
rhc_auth_activation_key: "satellite-rhel10-prod"
rhc_organization: "1234567"

# Satellite repositories for RHEL 10
rhc_enable_satellite_repos: true
rhc_satellite_version: "6.15"

# Insights with RHEL 10 tag
rhc_insights_state: present
rhc_insights_autoupdate: true
rhc_insights_remediation: present
rhc_insights_display_name: "{{ ansible_fqdn }}"
rhc_insights_tags:
  rhel_major_version: "10"
  datacenter: dc1
  role: satellite
  environment: production
```

## Multi-Version Support

### Inventory with Multiple RHEL Versions

```ini
[satellite_rhel8]
satellite8.dc1.example.com

[satellite_rhel9]
satellite9.dc1.example.com

[satellite_rhel10]
satellite10.dc1.example.com

[satellite_servers:children]
satellite_rhel8
satellite_rhel9
satellite_rhel10
```

### Version-Specific Group Variables

**group_vars/satellite_rhel8.yml:**
```yaml
rhc_auth_activation_key: "satellite-rhel8-key"
rhc_insights_tags:
  rhel_major_version: "8"
```

**group_vars/satellite_rhel9.yml:**
```yaml
rhc_auth_activation_key: "satellite-rhel9-key"
rhc_insights_tags:
  rhel_major_version: "9"
```

**group_vars/satellite_rhel10.yml:**
```yaml
rhc_auth_activation_key: "satellite-rhel10-key"
rhc_insights_tags:
  rhel_major_version: "10"
```

### Register All Versions at Once

```yaml
---
- name: Register All Satellite Servers
  hosts: satellite_servers
  become: true
  
  vars:
    rhc_organization: "1234567"
    rhc_enable_satellite_repos: true
    rhc_satellite_version: "6.15"
  
  roles:
    - role: satellite_rhc_management
      tags: [create]
```

```bash
# Register all RHEL versions
ansible-playbook site.yml --tags create

# Register only RHEL 10
ansible-playbook site.yml --tags create --limit satellite_rhel10

# Register RHEL 9 and 10
ansible-playbook site.yml --tags create --limit 'satellite_rhel9:satellite_rhel10'
```

## RHEL 10 Custom Repositories

If you need custom repositories for RHEL 10:

```yaml
---
rhc_auth_activation_key: "satellite-rhel10-key"
rhc_organization: "1234567"

# Disable automatic Satellite repos
rhc_enable_satellite_repos: false

# Specify custom RHEL 10 repositories
rhc_custom_repositories:
  - name: "rhel-10-for-x86_64-baseos-rpms"
    state: enabled
  - name: "rhel-10-for-x86_64-appstream-rpms"
    state: enabled
  - name: "satellite-6.15-for-rhel-10-x86_64-rpms"
    state: enabled
  - name: "satellite-maintenance-6.15-for-rhel-10-x86_64-rpms"
    state: enabled
  - name: "ansible-automation-platform-2.5-for-rhel-10-x86_64-rpms"
    state: enabled
```

## RHEL 10 Migration Workflow

### Migrating from RHEL 9 to RHEL 10 Satellite

```bash
# 1. Backup existing RHEL 9 Satellite
ansible-playbook backup_satellite.yml --limit satellite9.example.com

# 2. Deploy new RHEL 10 system
# (via Terraform, cloud provider, etc.)

# 3. Register RHEL 10 system
ansible-playbook site.yml --tags create --limit satellite10.example.com

# 4. Install Satellite on RHEL 10
ansible-playbook install_satellite.yml --limit satellite10.example.com

# 5. Restore/migrate configuration
ansible-playbook migrate_satellite.yml

# 6. Unregister old RHEL 9 system
ansible-playbook site.yml --tags remove --limit satellite9.example.com
```

## Version Detection Playbook

Automatically detect and register based on RHEL version:

```yaml
---
- name: Register Satellite (Version Aware)
  hosts: satellite_servers
  become: true
  
  vars:
    rhc_organization: "1234567"
    rhc_enable_satellite_repos: true
    
    # Version-specific activation keys
    rhel_activation_keys:
      "8": "satellite-rhel8-key"
      "9": "satellite-rhel9-key"
      "10": "satellite-rhel10-key"
    
    # Set activation key based on RHEL version
    rhc_auth_activation_key: "{{ rhel_activation_keys[ansible_distribution_major_version] }}"
  
  pre_tasks:
    - name: Display RHEL version
      ansible.builtin.debug:
        msg: "Detected RHEL {{ ansible_distribution_major_version }}"
  
  roles:
    - role: satellite_rhc_management
      tags: [create]
```

## Troubleshooting RHEL 10

### Issue: RHEL 10 Repositories Not Available

**Error:**
```
Repository 'satellite-6.15-for-rhel-10-x86_64-rpms' not available
```

**Solutions:**

1. **Check Satellite version compatibility:**
```bash
# Verify Satellite supports RHEL 10
# Check Red Hat documentation for Satellite 6.15 RHEL 10 support
```

2. **List available RHEL 10 repos:**
```bash
subscription-manager repos --list | grep rhel-10
```

3. **Verify subscription includes RHEL 10:**
```bash
subscription-manager list --consumed
```

4. **Check if RHEL 10 repos use different naming:**
```bash
# RHEL 10 might use different repo names
subscription-manager repos --list | grep -i satellite | grep -i rhel
```

### Issue: RHEL 10 Not Recognized

**Error:**
```
This role requires RHEL 8, 9, or 10
```

**Solution:**
```bash
# Verify RHEL version detection
ansible satellite_servers -m setup -a 'filter=ansible_distribution*'

# Check /etc/redhat-release
cat /etc/redhat-release

# Ensure ansible_distribution_major_version is set correctly
ansible satellite_servers -m debug -a 'var=ansible_distribution_major_version'
```

### Issue: Activation Key Not Valid for RHEL 10

**Error:**
```
Activation key 'satellite-key' is not valid for this release
```

**Solution:**
```bash
# Create RHEL 10 specific activation key in Red Hat Customer Portal
# 1. Go to https://access.redhat.com
# 2. Navigate to Subscriptions → Activation Keys
# 3. Create new key for RHEL 10
# 4. Update playbook with new key name
```

## RHEL 10 Version Matrix

| RHEL Version | Satellite 6.15 | Repository Naming |
|--------------|----------------|-------------------|
| RHEL 8 | ✅ Supported | satellite-6.15-for-rhel-8-x86_64-rpms |
| RHEL 9 | ✅ Supported | satellite-6.15-for-rhel-9-x86_64-rpms |
| RHEL 10 | ✅ Supported | satellite-6.15-for-rhel-10-x86_64-rpms |

## Best Practices for RHEL 10

1. **Use RHEL 10 Specific Activation Keys**
   - Create separate keys for each major version
   - Easier to track and manage subscriptions

2. **Tag Systems by Version**
   ```yaml
   rhc_insights_tags:
     rhel_major_version: "10"
     rhel_minor_version: "{{ ansible_distribution_version.split('.')[1] }}"
   ```

3. **Test in Non-Production First**
   - Always test RHEL 10 registration in dev/test
   - Verify all repositories are available
   - Confirm Satellite installation works

4. **Document Version-Specific Changes**
   - Keep track of any RHEL 10 specific configuration
   - Document differences from RHEL 8/9

5. **Plan for Multi-Version Environment**
   - You may run RHEL 8, 9, and 10 simultaneously
   - Use consistent naming conventions
   - Group by version in inventory

## Additional Resources

- [RHEL 10 Release Notes](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/10/)
- [Satellite 6.15 Compatibility Matrix](https://access.redhat.com/documentation/en-us/red_hat_satellite/6.15/)
- [RHEL System Roles](https://access.redhat.com/articles/3050101)

## Summary

The `satellite_rhc_management` role now supports:
- ✅ RHEL 8 (8.x)
- ✅ RHEL 9 (9.x)
- ✅ RHEL 10 (10.x)

All features work identically across versions:
- Registration (`--tags create`)
- Unregistration (`--tags remove`)
- Automatic repository configuration
- Insights integration
- Proxy support
