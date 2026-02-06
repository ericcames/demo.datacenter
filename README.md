Ansible Automation Platform Daily Demo for HashiCorp Terraform and Vault
=========
A demo designed to build the Infrastructure needed to showcase many of the use cases related to Terraform and Vault.  This builds two systems at AWS, one of the systems will become Terraform Enterprise and the other system will become Vault.  The infrastructure as code used in Day 1 setup uses community.general.terraform.

Notes
=========
1. This demo is designed to work with the Red Hat Demo Platform. Please see the aap.as.code repo below. [aap.as.code](https://github.com/ericcames/aap.as.code "aap.as.code")
2. This demo works with Amazon only currently.

Day 0 - Configuration as code (CAC) a repeatable build process for this demo
=========
Configuration as code give you an easy way to recover/move your ansible related artifacts to a new platform.  That includes your hardcoded credentials.  The hardcoded credentials can be safely vaulted in an ansible vault file.  Check out the setup_demo.yml for the configurations for setting up this demo using configuration as code.

[Setup - HashiCorp Daily Demo - CAC](https://github.com/ericcames/aap.dailydemo.hashicorp/blob/main/playbooks/setup_demo.yml "Setup - HachiCorp Daily Demo - CAC")<br>

Variables used in the setup template
```
my_vault: Eric Ames
timezone_id: America/Phoenix
my_remote_vault: >-
  https://raw.githubusercontent.com/ericcames/sourcefiles/refs/heads/main/vault_ames.yml
my_remote_ssh_pub_key: >-
  https://raw.githubusercontent.com/ericcames/sourcefiles/refs/heads/main/id_rsa.pub
```

Day 1 - Infrastructure as code (IAC) a repeatable build process for the HashiCorp Terraform and Vault servers.
=========

[Daily Demo HashiCorp Create/Remove](https://github.com/ericcames/aap.dailydemo.hashicorp/blob/main/playbooks/main.yml "Daily Demo HashiCorp Create/Remove")<br>
![alt text](https://github.com/ericcames/aap.dailydemo.hashicorp/blob/main/images/hashimain.png "Main Playbook")<br>

Tag used:
```
create
  or
remove
```
![alt text](https://github.com/ericcames/aap.dailydemo.hashicorp/blob/main/images/vpc.png "VPC")<br>
![alt text](https://github.com/ericcames/aap.dailydemo.hashicorp/blob/main/images/s3.png "s3 bucket")<br>
![alt text](https://github.com/ericcames/aap.dailydemo.hashicorp/blob/main/images/53.png "Route 53")<br>
![alt text](https://github.com/ericcames/aap.dailydemo.hashicorp/blob/main/images/ec2.png "ec2 nodes")<br>
![alt text](https://github.com/ericcames/aap.dailydemo.hashicorp/blob/main/images/eip.png "Elastic IPs")<br>
![alt text](https://github.com/ericcames/aap.dailydemo.hashicorp/blob/main/images/inventory.png "Inventory")<br>