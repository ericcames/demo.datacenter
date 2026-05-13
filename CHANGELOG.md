# Changelog

All notable changes to this repo are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project does not yet follow Semantic Versioning; entries are grouped under
`[Unreleased]` until a release cadence is established.

## [Unreleased]

### Added
- `.envrc.example` at repo root with placeholders for AWS credentials, documenting the direnv-based local-iteration workflow ([#24](https://github.com/ericcames/demo.datacenter/pull/24)).
- `/opus-review` slash command for one-shot architecture review of `PLANNING.md` and `CLAUDE.md` ([#6](https://github.com/ericcames/demo.datacenter/pull/6)).
- Initial `CLAUDE.md` (project instructions for Claude Code) and `PLANNING.md` (strategy / decision log) ([#5](https://github.com/ericcames/demo.datacenter/pull/5)).
- Opus-review assessment of `PLANNING.md` and `CLAUDE.md` committed under `docs/` ([#7](https://github.com/ericcames/demo.datacenter/pull/7)).

### Changed
- `terraform_cli/data.tf` RHEL 9 AMI source switched from Red Hat official AMIs to CIS-hardened AMIs built by `image.builder.pipeline`; owner pinned to `463606842039` (Red Hat Image Builder service account) with tag filters `Pipeline=image-builder-pipeline`, `OS=rhel9`, `CIS-Level=L1` ([#14](https://github.com/ericcames/demo.datacenter/pull/14), closes [#9](https://github.com/ericcames/demo.datacenter/issues/9)).
- `terraform_cli/main.tf` `aws_instance.satellite` AMI source corrected from `rhel10` to `rhel9`; Satellite 6.18 requires RHEL 9 ([#14](https://github.com/ericcames/demo.datacenter/pull/14)).
- Default AWS region: `us-west-1` → `us-east-1` in both AAP-rendered (`roles/infrastructure/vars/main.yml`) and CLI-iteration (`terraform_cli/main.tf`) paths, plus all doc examples ([#20](https://github.com/ericcames/demo.datacenter/pull/20), closes [#16](https://github.com/ericcames/demo.datacenter/issues/16)).
- Pin `terraform-aws-modules/key-pair/aws` to `~> 2.0` in `terraform_cli/main.tf` to prevent surprise major-version upgrades ([#21](https://github.com/ericcames/demo.datacenter/pull/21)).
- `terraform_cli/README.md` rewritten to walk through the direnv install → hook → `.envrc allow` workflow; inline access-key example removed from `CLAUDE.md` ([#24](https://github.com/ericcames/demo.datacenter/pull/24)).

### Fixed
- `terraform_cli/main.tf` subnets `public_a`/`public_c` AZs pinned to `us-east-1a`/`us-east-1c` respectively; previously unset, AWS could assign `us-east-1e` which does not support `m5.2xlarge` (Satellite) causing `terraform apply` to fail ([#14](https://github.com/ericcames/demo.datacenter/pull/14)).
- `terraform_cli/main.tf` `aws_instance.key_name` references updated from `"my_public_ssh_key"` to `"my_public_ssh_key_tf"` (11 occurrences). Completes the rename started in `8adaf67` so a fresh-account `terraform apply` no longer fails on missing key ([#25](https://github.com/ericcames/demo.datacenter/pull/25), closes [#22](https://github.com/ericcames/demo.datacenter/issues/22)).
