# DC1 Demo Datacenter — Planning Document

> **Purpose of this document:** Capture every architectural decision, its rationale, and the
> prioritized work list so that any engineer (or Claude session) can pick up this project
> cold without re-deriving context from scratch.
>
> Last updated: 2026-05-05

---

## Vision

DC1 is a unified virtual datacenter running on AWS, managed entirely through Configuration
as Code using Ansible Automation Platform. It replaces a collection of isolated, one-off
demo repos with a single shared infrastructure foundation that all demo scenarios run on top of.

The customer story:

> *"We built your datacenter with code. Now watch us operate it."*

DC1 supports two demo modes:
- **Watch it build** — demonstrate the full automated deployment to the customer in real time
- **Day 2 operations** — pre-build DC1 ahead of a meeting, then demonstrate day-to-day
  operations (patching, user management, secret rotation, network automation, etc.)

---

## Guiding Principles

1. **Additive only** — old standalone demos remain runnable until their DC1 equivalents are
   proven. Nothing is retired until its replacement passes a full smoke test.
2. **Layer order is enforced** — each layer must be stable before building on top of it.
3. **Validation is not optional** — every setup playbook ends with an explicit post-setup
   verification task. Green means actually green.
4. **CaC for everything** — every AAP object (credential, project, template, workflow,
   inventory) is defined in code and reproducible from scratch.
5. **ansible.platform over ansible.controller** — `ansible.platform` modules are the
   current standard. `ansible.controller` is legacy and must not be introduced in new code.
6. **Token hygiene** — any playbook that creates an AAP token must delete it in an
   `always:` block. No stale tokens.
7. **No secrets in the repo** — manifests, passwords, keys are fetched at runtime from
   the remote vault. Nothing sensitive is committed.

---

## Architecture

DC1 is a layered stack. Each layer is a prerequisite for the layers above it.

```
┌─────────────────────────────────────────────────────────────────┐
│  Layer 4 — Demo Stories                                         │
│  Patching · Windows mgmt · Network automation · ITSM/EDA        │
├─────────────────────────────────────────────────────────────────┤
│  Layer 3 — Workloads                                            │
│  RHEL nodes (Satellite-managed) · Windows nodes (AD-joined)     │
│  Applications (websites, LAMP stack)                            │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2 — Network & Security Appliances                        │
│  F5 BIG-IP · Palo Alto NGFW                                     │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1 — Core Services                                        │
│  Red Hat Satellite · Active Directory · HashiCorp Vault         │
│  Infoblox (DNS/IPAM) · Red Hat IdM                              │
├─────────────────────────────────────────────────────────────────┤
│  Layer 0 — AWS Infrastructure                                   │
│  Terraform: VPC · Subnets · Security Groups · EC2 nodes         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Layer 0 — Foundation Rework

Layer 0 was previously marked Complete. A foundation review
([`docs/reviews/opus-review-2026-05-05.md`](docs/reviews/opus-review-2026-05-05.md))
identified work that must land before the layer can be safely declared done.
Until the items below resolve, the layer is in **reopen / in progress** state.

| Issue | Scope |
|-------|-------|
| [#9](https://github.com/ericcames/demo.datacenter/issues/9) | Consume CIS-hardened RHEL AMIs from `image.builder.pipeline` (tag-based discovery, owner=`self`) |
| [#10](https://github.com/ericcames/demo.datacenter/issues/10) | Terraform state — migrate to S3 backend + DynamoDB lock; unify the two divergent state files; drop the ZIP/providers archive and `force_init: true` |
| [#11](https://github.com/ericcames/demo.datacenter/issues/11) | Terraform lint/CI baseline — `terraform fmt`/`validate` in GitHub Actions; pre-commit mirror |
| [#12](https://github.com/ericcames/demo.datacenter/issues/12) | Bug 4 — migrate `ansible.controller` calls in `roles/infrastructure/tasks/main.yml` to `ansible.platform` |

When all four issues close and a clean end-to-end provision + destroy run
succeeds from a fresh AWS account, mark Migration Sequence row 1 ✅ Complete.

---

## Isolation Model

Each sales engineer has their own completely isolated environment:

- Their own RHDP AWS open environment (separate AWS account)
- Their own RHDP AAP instance
- Their own S3 state bucket (named uniquely within their account)
- Their own VPC and EC2 instances
- Their own remote vault file with their own credentials

**There is no shared infrastructure between engineers.** Two engineers running DC1
simultaneously have zero conflict at the AWS level because they are in separate accounts.

This means:
- Terraform workspaces are **not needed** — no namespacing required
- Per-user resource name prefixes are **not needed**
- The same Terraform code runs identically for every engineer in their own account

---

## Infrastructure Tiers

The full DC1 stack is not always needed. The Terraform template will use boolean feature
flags so each engineer can bring up only what they need for the work at hand.

### Tier 1 — Networking (always-on, near-zero cost)
| Resource | Notes |
|----------|-------|
| VPC | `10.0.0.0/16` |
| Public subnets A + C | `10.0.1.0/24`, `10.0.2.0/24` |
| Internet gateway + route table | |
| Security group | |
| S3 state bucket | Terraform remote state + provider archive |

Cost: pennies per day. Leave this up permanently.

### Tier 2 — Core Services (up when actively developing or pre-building for a demo)
| Instance | Type | ~$/day |
|----------|------|--------|
| Satellite | m5.2xlarge | $9.22 |
| Active Directory (Windows Server 2025) | m5.xlarge | $4.61 |
| HashiCorp Vault | t2.micro | $0.28 |
| RHEL web node A | t2.micro | $0.28 |
| RHEL web node C | t2.micro | $0.28 |
| **Total** | | **~$14.67/day** |

### Tier 3 — On-demand Appliances (spin up for specific demo scenarios only)
| Instance | Type | ~$/day | Demo scenario |
|----------|------|--------|---------------|
| F5 BIG-IP | m5.xlarge | $4.61 | F5 / network automation |
| Palo Alto NGFW | c5n.xlarge | $5.18 | Network security |
| Infoblox | m5.xlarge | $4.61 | DNS/IPAM automation |
| RHEL (Containerlab) | t2.medium+ | ~$1.00 | Network device emulation |
| Red Hat IdM | t2.micro | $0.28 | IdM + AD trust |
| HashiCorp Enterprise | t2.micro | $0.28 | Enterprise Terraform/Vault |

**Stop/start, not terminate/recreate.** Once an instance is configured, stop it when not
in use. AWS charges only for EBS storage (~$0.10/GB/month) when stopped. Restarting a
pre-configured Satellite takes under 2 minutes vs. 30+ minutes to reinstall from scratch.

The nightly OS-level shutdown cron (currently in `linux_post_install`) should be **removed**
entirely. Cost management is handled by stopping AWS instances, not by OS shutdown.

---

## DNS Strategy

No real DNS domain registration or management is required.

### External access (customer browser, SE laptop)
Use **nip.io** — a free public DNS service where the IP is embedded in the hostname:

```
satellite.54.183.12.4.nip.io  →  resolves to 54.183.12.4  (Satellite web UI)
ad.54.183.12.8.nip.io         →  resolves to 54.183.12.8  (AD management)
vault.54.183.12.9.nip.io      →  resolves to 54.183.12.9  (Vault UI)
```

No setup required. Works globally the moment Terraform apply finishes. After provisioning,
a post-provision play reads Terraform outputs, constructs nip.io hostnames, and registers
them as inventory host vars.

### Internal (server-to-server within the VPC)
The `linux_post_install` role already generates `/etc/hosts` from a Jinja2 template.
Once Infoblox is configured, it becomes the authoritative internal DNS and `/etc/hosts`
management can be retired.

### Active Directory domain
The AD domain name is **internal to the VPC only**. AD runs its own DNS server for the
domain — no external resolution required.

**Chosen AD domain: `dc1.lab`**

Rationale:
- Completely internal — no external DNS dependency
- Unambiguous `.lab` TLD signals a lab/demo environment
- Does not conflict with the publicly-owned `kona.services` domain
- Microsoft recommends not using the apex of a real public domain for AD
- The same domain name (`dc1.lab`) works identically for every engineer in their own VPC

When Infoblox is set up, it will serve as the authoritative DNS for `dc1.lab` internally,
which becomes its own demo story (Ansible registers new nodes in Infoblox DNS automatically).

---

## Satellite Manifest

The committed binary `roles/satellite/files/AmesCO-Satellite-manifest.zip` is **expired**
and must be replaced. It should not be committed to the repo — manifests are account-specific
and time-limited.

**Decision: generate the manifest at runtime via the Red Hat Subscription Management API.**

The RHSM API (`api.access.redhat.com/management/v1/allocations`) can create and export a
manifest programmatically. Credentials (`customer_portal_username`, `customer_portal_password`)
are already in the remote vault. The Satellite role will be updated to:

1. Call the RHSM API to create/refresh an allocation for this Satellite instance
2. Export and download the manifest ZIP
3. Upload it to Satellite

This makes Satellite setup fully self-contained and reproducible with no manual steps.

---

## Network Device Emulation (RHEL / Containerlab)

The Containerlab node runs on RHEL 9 — consistent with the rest of DC1 so it is
Satellite-managed, Insights-visible, and IdM-joinable. Containerlab supports RHEL; there
is no functional regression from dropping Ubuntu.

Teammate **mlowcher** ([GitLab](https://gitlab.com/users/mlowcher) /
[GitHub](https://github.com/mlowcher61)) may have already developed a Containerlab setup
role. Confirm with him before building a new one to avoid duplicate work.

---

## HashiCorp Vault (Priority) vs HashiCorp Enterprise

**Vault is the higher priority.** The demo story is: *"Store your secrets in HashiCorp Vault
instead of in AAP."*

What the Vault role needs to do:
1. Install HashiCorp Vault on the `vault` RHEL node
2. Initialize Vault and store the unseal keys + root token in the remote ansible-vault file
3. Configure a KV secrets engine
4. Wire AAP to pull credentials from Vault (HashiCorp Vault credential type in AAP)
5. Demo playbooks use `community.hashi_vault` to retrieve secrets at runtime

HashiCorp Enterprise (Terraform Cloud, Vault Enterprise) comes later and is lower priority.

---

## Active Directory

The Windows Server 2025 node is already provisioned by Terraform (tagged `ad`, `m5.xlarge`).
The WinRM group vars are already set in the infrastructure role. What is missing is the
Ansible role to configure it.

**Hardening approach:** Marketplace Windows Server 2025 AMI is used as-is. Post-AD-join,
Group Policy Objects (GPOs) enforce the security baseline — this is the standard Windows
hardening model and appropriate for the demo audience. CIS-hardened Windows AMIs from
`image.builder.pipeline` are deferred to Phase 3 of that pipeline (see [#19](https://github.com/ericcames/demo.datacenter/issues/19)).

The `active_directory` role needs to:
1. Promote the Windows Server to a Domain Controller for `dc1.lab`
2. Configure AD DNS to serve the `dc1.lab` zone
3. Create a demo OU structure (`Users`, `Computers`, `Groups`)
4. Create demo users and groups that can be managed via AAP
5. Configure AAP LDAP integration so AAP authenticates against AD
6. Create an AAP credential for AD management

This unlocks the demo story: *"Manage Active Directory users and groups from AAP."*

---

## Red Hat IdM

The `idm` RHEL node is provisioned but has no role. IdM depends on AD being complete first.

The IdM story is:
1. Install Red Hat IdM on the `idm` node
2. Configure an IdM ↔ AD trust for `dc1.lab`
3. Demonstrate IdM day-2 operations (user lifecycle, policy) via AAP

**IdM is sequenced after AD is stable.**

---

## Teardown and Cleanup

When DC1 is torn down (or an instance is terminated), the following must be cleaned up to
avoid orphaned entries in Red Hat services:

1. **Insights**: `insights-client --unregister` before RHSM unregistration
2. **Red Hat CDN**: `subscription-manager unsubscribe --all && subscription-manager unregister`
   (the `rhsm` role `remove` tag already calls `rhc_state: absent` which handles this —
   verify Insights is also caught)
3. **console.redhat.com**: entries should disappear after #1 and #2 complete

These cleanup steps must run before `terraform destroy`. The workflow is:
```
ansible-playbook --tags remove   # deregisters everything
terraform destroy                # terminates instances
```

---

## Known Bugs (fix before building new features)

| # | File | Issue | Priority |
|---|------|-------|----------|
| 1 | `roles/satellite/files/AmesCO-Satellite-manifest.zip` | Manifest is expired; replace with API-based generation | Blocking |
| 2 | `roles/rhsm/tasks/main.yml:14` | Debug task prints `rh_activation_key` and `rh_org_id` in plaintext to AAP job output | High |
| 3 | `roles/infoblox_setup/tasks/setup_aap_credential.yml:73` | Uses `awx.awx.credential` (legacy); migrate to `ansible.platform` or `infra.aap_configuration` | High |
| 4 | `roles/infrastructure/tasks/main.yml:115,121` | Uses `ansible.controller.inventory_source_update` and `ansible.controller.group`; migrate to `ansible.platform` | High |
| 5 | `playbooks/sat_only.yml:7-9` | `remote_vault` role is commented out; playbook will fail to resolve vault variables when run standalone | Medium |
| 6 | `roles/linux_post_install/tasks/main.yml` | Removes cockpit (`state: absent`) but then creates `/etc/cockpit/` and copies `cockpit.conf` — contradictory | Medium |
| 7 | repo root | No `CHANGELOG.md` — required by project standards | Medium |
| 8 | `roles/linux_post_install/tasks/main.yml` | Nightly shutdown cron should be removed; cost management is handled at the AWS layer | Low |

---

## Prioritized Work Items

### Phase 1 — Foundation (do before anything else)

1. **Fix all known bugs** (table above) — unblocks clean development
2. **Modular Terraform refactor** — add boolean feature flags per component tier so
   engineers can bring up only what they need. Each flag maps to a Terraform `count`
   conditional on the relevant `aws_instance` resources.
3. **Add `CHANGELOG.md`**

### Phase 2 — Complete Layer 1

4. **Satellite manifest via API** — remove committed zip, implement RHSM API call in the
   satellite role to generate and upload a fresh manifest at setup time
5. **Active Directory role** — `dc1.lab` domain, demo OU structure, AAP LDAP integration
6. **HashiCorp Vault role** — install, initialize, KV secrets engine, AAP credential type wiring
7. **Post-setup validation** — every layer setup play must assert that what it built actually
   works before exiting green

### Phase 3 — Layer 1 Completion + Layer 2

8. **Infoblox DNS wiring** — configure Infoblox as authoritative DNS for `dc1.lab`;
   fix `awx.awx` → `ansible.platform` in `infoblox_setup` role
9. **Red Hat IdM role** — install IdM, configure AD trust for `dc1.lab`
10. **F5 BIG-IP role** — migrate from `aap.dailydemo.F5` into DC1 context
11. **Palo Alto role** — migrate from `aap.dailydemo.Panos` into DC1 context

### Phase 4 — Layer 3 + Layer 4

12. **Containerlab role** — RHEL node setup; confirm/reuse mlowcher's work if available
13. **RHEL workload nodes** — Satellite-managed, joined to `dc1.lab` DNS
14. **Windows workload nodes** — AD-joined, managed via AAP
15. **Demo story playbooks** — Linux patching, Windows management, network automation,
    EDA/ITSM integration

---

## Migration Sequence (from standalone demos)

| Step | Component | Source | Status |
|------|-----------|--------|--------|
| 1 | AWS Infrastructure | demo.datacenter | 🔄 Reopen (foundation rework — see "Layer 0 — Foundation Rework" section) |
| 2 | Red Hat Satellite | aap.dailydemo.satellite | ✅ Migrated (manifest bug open) |
| 3 | Active Directory | aap.dailydemo.windows | 🔄 In Progress |
| 4 | HashiCorp Vault | new | ⬜ Not Started |
| 5 | Infoblox DNS/IPAM | new | ⬜ Not Started |
| 6 | Red Hat IdM | new | ⬜ Not Started |
| 7 | F5 BIG-IP | aap.dailydemo.F5 | ⬜ Not Started |
| 8 | Palo Alto NGFW | aap.dailydemo.Panos | ⬜ Not Started |
| 9 | Containerlab | mlowcher (TBC) | ⬜ Not Started |
| 10 | RHEL workload nodes | aap.dailydemo.linux | ⬜ Not Started |
| 11 | Windows workload nodes | aap.dailydemo.windows | ⬜ Not Started |
| 12 | Demo story playbooks (Layer 4) | all daily demo repos | ⬜ Not Started |

---

## Open Questions

| Question | Status |
|----------|--------|
| Containerlab role — does mlowcher have one? | Ask him (RHEL node, not Ubuntu) |
| Satellite manifest API — exact RHSM API endpoint and allocation workflow | Needs a spike |
| Vault unseal keys storage — confirmed going into ansible-vault file in remote vault | Confirmed |

---

## Resolved Decisions (do not re-debate these)

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Multi-user isolation | Per-SE AWS account, no shared infra | Each SE has own RHDP open env |
| Terraform workspaces | Not needed | Separate AWS accounts provide isolation |
| DNS for external access | nip.io | No domain registration required, works immediately |
| AD domain | `dc1.lab` | Internal-only, unambiguous, no public DNS conflict |
| DNS domain = AD domain? | No — different purposes | nip.io is dynamic/external; AD domain is permanent/internal |
| GoDaddy automation | Not needed | nip.io eliminates the requirement |
| Nightly OS shutdown | Remove it | AWS stop/start handles cost; shutdown is redundant |
| Satellite manifest | API-based generation | Committed zip is expired; API is repeatable |
| Network emulation tool | Containerlab | Best Ansible integration, container-based |
| Containerlab host OS | RHEL 9 | Platform consistency (Satellite-managed, Insights-visible, IdM-joinable); one less OS family; no confirmation from Mark that Ubuntu is needed for Cisco demos ([#18](https://github.com/ericcames/demo.datacenter/issues/18)) |
| Windows CIS hardening | Deferred — GPO post-join | AD-joined Windows hosts get hardening from GPOs regardless of pre-image baseline; `image.builder.pipeline` targets Windows in Phase 3 (Server 2022, not 2025); demo audience is general enterprise, not federal/regulated ([#19](https://github.com/ericcames/demo.datacenter/issues/19)) |
| Vault vs HashiCorp Enterprise | Vault is higher priority | Core demo story: secrets in Vault, not AAP |
| Stop vs terminate/recreate | Stop/start | Preserves configured disk state; restart in minutes not hours |
| ansible.platform vs ansible.controller | ansible.platform always | ansible.controller is legacy |
| Terraform state strategy | S3 backend + DynamoDB lock | Replaces hand-rolled ZIP/providers archive; unifies AAP path and `terraform_cli/` onto one state file |
| CIS image baseline | L1 for all RHEL | Matches `image.builder.pipeline` Phase 1 contract; Satellite host = L1 only; Layer 3 workloads start L1, add L2 per workload group once pipeline ships L2 lineage (see [#9](https://github.com/ericcames/demo.datacenter/issues/9)) |
| AWS region | `us-east-1` | Pipeline default; 6 AZs (vs us-west-1's 2); broadest instance and marketplace AMI availability; eliminates cross-region AMI dance with `image.builder.pipeline` (see [#16](https://github.com/ericcames/demo.datacenter/issues/16)) |

---

## Related Repositories

| Repo | Purpose | Status |
|------|---------|--------|
| [aap.as.code](https://github.com/ericcames/aap.as.code) | Master bootstrap / entry point for all demos | Active |
| [demo.datacenter](https://github.com/ericcames/demo.datacenter) | DC1 — this repo | In Development |
| [aap.dailydemo.F5](https://github.com/ericcames/aap.dailydemo.F5) | F5 daily demo (active, Phase 1 bugs resolved) | Active |
| [aap.dailydemo.linux](https://github.com/ericcames/aap.dailydemo.linux) | Linux daily demo | Active |
| [aap.dailydemo.windows](https://github.com/ericcames/aap.dailydemo.windows) | Windows daily demo | Active |
| [aap.dailydemo.Panos](https://github.com/ericcames/aap.dailydemo.Panos) | Palo Alto daily demo | Active |
| [aap.dailydemo.hashicorp](https://github.com/ericcames/aap.dailydemo.hashicorp) | HashiCorp daily demo | Active |

---

*Update this document as decisions are made and work items are completed.
Open GitHub Issues in `demo.datacenter` for individual work items, using this as the
strategic reference. The ROADMAP.md in `aap.as.code` tracks the broader migration sequence.*
