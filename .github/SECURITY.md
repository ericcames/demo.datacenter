# Security Policy

## Scope

This is a **Configuration as Code framework** for a virtual demo datacenter on AWS. It contains no production credentials, no customer data, and no live service endpoints. All sensitive values (AWS credentials, Red Hat tokens, vault passwords) are resolved at runtime from environment variables and a remote vault URL and are never committed.

## Supported Versions

Only the latest commit on `main` is maintained.

## Reporting a Vulnerability

Because this is a demo/automation repo with no production exposure, **open a public GitHub issue** to report any security concerns. There is no need for private disclosure.

When reporting, include:

- A description of the issue
- The file(s) affected
- Any suggested fix if you have one

## What Should Never Be Committed

As a reminder — these are never committed to this repo:

- Credentials, tokens, or passwords of any kind
- `.envrc` (contains AWS credentials — gitignored; copy from `.envrc.example`)
- Terraform state files (`*.tfstate`) — state lives in S3
- `terraform_cli/scripts/win25_userdata` (gitignored — contains Windows setup script)
- Any file matching `*.tfvars` or `*.tfvars.json`

If you spot any of the above committed by mistake, open an issue immediately.
