# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

`demo.datacenter` is the Configuration as Code (CaC) framework for **Datacenter 1 (DC1)** — a virtual datacenter built on AWS and managed entirely through Ansible Automation Platform (AAP). It is designed to be bootstrapped via the [aap.as.code](https://github.com/ericcames/aap.as.code) repo and run as AAP Job Templates, not directly from the CLI.

## Architecture

DC1 is built in layers:

| Layer | Component | Status |
|-------|-----------|--------|
| 0 | AWS Infrastructure (Terraform) | 🔄 In progress (foundation rework — see PLANNING.md "Layer 0 — Foundation Rework") |
| 1 | Satellite 6.18 | Complete |
| 1 | Active Directory | In progress |
| 1 | Infoblox | Provisioned, not set up |
| 2 | F5, Palo Alto | Not started |
| 3 | RHEL/Windows Workloads | Not started |

## Key Playbooks

| Playbook | AAP Job Template | Purpose |
|----------|-----------------|---------|
| `playbooks/main.yml` | DC1 - Infrastructure Management (Terraform) | Create/destroy AWS infrastructure |
| `playbooks/satellite_setup.yml` | DC1 - Satellite Setup | Install and configure Satellite 6.18 |
| `playbooks/sat_only.yml` | — | Satellite configuration only |
| `playbooks/infoblox/playbook_infoblox_complete_setup.yml` | — | Full Infoblox initial setup |

## Roles

- **infrastructure** — Provisions AWS instances via Terraform. Renders TF configs from Jinja2 templates, uploads them to S3, and runs `community.general.terraform`. State lives in the S3 backend (`backend.tf.j2`); destroy runs re-download configs from S3 and run `terraform init` to reconnect to the backend.
- **satellite** — Installs Satellite 6.18 on RHEL 9, uploads manifest, creates lifecycle environments (Library → Development → QA → Production), content views, activation keys, and hostgroups.
- **rhsm** — Registers hosts with Red Hat subscription manager. Requires `rh_activation_key` and `rh_org_id` from vault.
- **remote_vault** — Fetches a remote vault file from `{{ my_remote_vault }}` URL and loads it with `include_vars`. Used in every play that needs secrets.
- **linux_post_install** — Common RHEL post-install config (Cockpit, MOTD, SSH banner, nightly shutdown, `/etc/hosts` from template).
- **infoblox_setup** — Initialises a fresh Infoblox appliance: changes default admin password, creates a dedicated `ansible` service account, and registers an AAP credential.

## Runtime Patterns

**Tags** drive create vs. destroy:
```bash
# Provision
ansible-playbook playbooks/main.yml --tags create

# Tear down
ansible-playbook playbooks/main.yml --tags remove
```

**Remote vault**: Secrets are never stored in the repo. Every play calls the `remote_vault` role (or equivalent) to download a YAML file from `{{ my_remote_vault }}` before use.

**AAP token lifecycle**: Any role that creates a token via `ansible.platform.token` must remove it in the same task block. The `infrastructure` role shows the pattern — token created in `always:`, removed at the end of each block.

**AAP environment variables**: The infrastructure role asserts that `CONTROLLER_HOST`, `CONTROLLER_USERNAME`, and `CONTROLLER_PASSWORD` are set (injected by AAP credentials). Do not hardcode these.

**Terraform state persistence**: Both the AAP path and `terraform_cli/` share a single S3 backend (`backend.tf.j2`; `backend "s3" {}` in `terraform_cli/terraform.tf`). State key is `demo-datacenter/terraform.tfstate`; locking uses `use_lockfile = true` (Terraform ≥ 1.10, no DynamoDB required). The S3 bucket is created fresh at the start of every `--tags create` run (pre-flight delete ensures no stale state) and torn down at the end of `--tags remove`. For `terraform_cli/`, set `MY_S3_BUCKET_NAME` and `TF_CLI_ARGS_init` in `.envrc` (see `.envrc.example`).

## Collection Conventions

- Use `ansible.platform` modules (e.g., `ansible.platform.token`) — not `ansible.controller` — wherever possible. `ansible.controller` is legacy.
- Pinned versions live in `collections/requirements.yml` and mirrored in `galaxy.yml`. Update both when changing a version.
- Minimum Ansible version: **2.16.14** (`meta/runtime.yml`).

## Terraform CLI Development

`terraform_cli/` contains standalone TF configs for iterating locally without AAP. Credentials are loaded from `.envrc` (gitignored) via direnv when you `cd` into the repo. See `terraform_cli/README.md` for first-time setup; `.envrc.example` at repo root is the template.

Then use standard Terraform workflow:
```bash
cd terraform_cli/
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
terraform destroy
```

To find AMI IDs:
```bash
aws ec2 describe-images --query 'reverse(sort_by(Images, &CreationDate))[].[Name, ImageId, CreationDate]' \
  --filters 'Name=name,Values=F5*BIGIP-*' --output table --region us-east-1
```

## Installing Collections

```bash
ansible-galaxy collection install -r collections/requirements.yml -p ./collections/
```

## Vault Variables Required

| Variable | Used by | Description |
|----------|---------|-------------|
| `my_remote_vault` | remote_vault role | URL to the remote vault YAML |
| `rh_activation_key` | rhsm role | Red Hat activation key |
| `rh_org_id` | rhsm role | Red Hat organisation ID |
| Satellite credentials | satellite role | Set in `roles/satellite/vars/main.yml` (overridden by vault) |

## What Not to Commit

`.gitignore` excludes: `.terraform/`, `*.tfstate`, `*.tfvars`, `win25_userdata`. State is managed by the S3 backend; no local state files should be committed.

Images belong in `docs/images/` and must be committed (not gitignored) so they render on GitHub.
