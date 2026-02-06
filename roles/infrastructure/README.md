infrastructure
=========
```
This role will create or delete infrasturce at aws using community.general.terraform
```
Requirements
------------
```
Amazon Web Console Account
Amazon Web Services Credential in Ansible Automation Platform
```
Role Variables
--------------
```
ssh_key_name: my_public_ssh_key
email_address: eames@redhat.com # the email address used to send emails from the demo
# AWS information
# this section is only used by deploy-hosts.yml for AWS deployment. Other deployments don't need it.
aws_profile: default                        # aws profile name from ~/.aws/credentials
aws_ami: ami-0a5229853eaaa29c1              # Red Hat Enterprise Linux version 10 (HVM), EBS General Purpose (SSD) Volume Type
aws_type: m7i.xlarge                        # 4 vCPUs, 16 GiB RAM 4g EPYC
aws_domain: "{{ domain_name }}"
aws_region: us-west-1
my_s3_bucket_name: hashicorp-daily-demo-451
tf_config_files:
  - main.tf
  - backend.tf
ansible_python_interpreter: /usr/bin/python3
```
Dependencies
------------
```
amazon.aws
```
Example Playbook
----------------
```
---
- name: Provision terraform and vault
  hosts: localhost
  connection: local

  tasks:

    - name: Include the infrastructure role
      tags:
        - create
      ansible.builtin.include_role:
        name: infrastructure

    - name: Include the infrastructure role
      tags:
        - remove
      ansible.builtin.include_role:
        name: infrastructure

```
License
-------

https://opensource.org/license/mit
