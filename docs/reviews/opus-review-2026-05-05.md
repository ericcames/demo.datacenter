# Opus Review — PLANNING.md & CLAUDE.md

> Generated: 2026-05-05
> Scope: challenge the architecture before significant Phase 1 work begins.
> Source: `/opus-review` skill run against `PLANNING.md` and `CLAUDE.md`.

The plan is coherent and well-scoped, but it leaves several load-bearing
decisions unsupported and asserts patterns the code does not actually
implement. Below are the items to resolve **before** Phase 1 begins.

---

## 1. Stated patterns the code violates (these belong on the bug list)

The "token hygiene" pattern is one of the guiding principles, and CLAUDE.md
says *"token created in `always:`, removed at the end of each block."* The
actual code does not do this:

- `roles/infrastructure/tasks/main.yml:28-36` — token created in a regular
  `block:`, not in `always:`.
- Lines 136-142 — token removal is the last *normal* task in the create
  block. If anything between lines 38 and 136 fails (Terraform apply, S3
  put, archive, inventory update), the token leaks. This is exactly the
  failure mode the principle is meant to prevent.
- The `remove` block (lines 144+) does not appear to create or revoke a
  token at all — verify.

Other "stated but not implemented" gaps:

- `roles/rhsm/tasks/main.yml:14` doesn't just print secrets — the entire
  `rhsm` role is included only on the `satellite` host in
  `playbooks/main.yml`, so it won't deregister the rest of DC1 as it grows.
  Layer 3 will inherit this bug silently.
- `force_init: true` (`infrastructure/tasks/main.yml:92`) re-downloads
  providers on every run, defeating the "providers in S3" optimization
  that justifies the ZIP/S3 dance.
- Hardcoded `inventory: "Datacenter 1"` and
  `organization: "IT Service Automation"` (lines 116-117) couple DC1 to
  one specific AAP layout. Per-SE isolation only holds if every SE's
  `aap.as.code` bootstrap creates those exact names.
- `ansible.controller 4.7.4` is pinned in `collections/requirements.yml`
  and in `galaxy.yml` despite the "never use in new code" policy. Drop
  it the moment bug #4 lands.
- `awx.awx.credential` is used in
  `roles/infoblox_setup/tasks/setup_aap_credential.yml:73` but `awx.awx`
  is **not** in `collections/requirements.yml`. A clean install would
  fail. Verify.
- WinRM connection variables (transport, ports, timeouts) are pushed via
  API call against an AAP group instead of living in inventory
  `group_vars/`. That is data-as-code masquerading as runtime API drift.

None of these are in the Known Bugs table. They should be.

---

## 2. Architectural decisions that are underdeveloped

**Terraform state strategy.** The current pattern — `force_init: true`,
ZIP `.terraform/`, push to S3, retrieve on remove — is hand-rolled and
brittle. Use the native S3 backend with DynamoDB locking. It is one block
of Terraform config and removes both the ZIP step and the second tfstate
that lives at `terraform_cli/terraform.tfstate`. As written, you have
*two* state files (AAP path and CLI path) that will diverge.

**AD domain `dc1.lab`.** The rationale in PLANNING.md is partially wrong.
`.lab` is **not** an IETF/RFC-reserved TLD — it's an unreserved string
ICANN could delegate at any time, exactly the failure mode you're trying
to avoid. The Microsoft guidance you cite says don't use the *apex* of
a domain you own; using a *subdomain* (`dc1.kona.services`) is the
textbook recommendation and is what Microsoft actually suggests. Safer
alternatives, in order: `dc1.kona.services` → `dc1.internal`
(ICANN-reserved 2024) → `dc1.home.arpa`. Note this in "Resolved
Decisions" only after picking with the reasoning corrected.

**Vault unseal-key storage.** Storing them in the same ansible-vault
remote vault undermines the demo narrative ("don't keep secrets in AAP,
keep them in Vault") — a customer will ask "OK, where do the unseal keys
live?" and the answer is "an ansible-vault file we fetch over HTTP."
Decide upfront: AWS KMS auto-unseal, Shamir split among SEs, or own the
awkwardness in the script. Don't leave this for "later."

**Containerlab on Ubuntu.** A non-RHEL node in a Red Hat demo platform
is a tell. It also breaks the Satellite/Insights/IdM consistency story
for Layer 3. Containerlab runs fine on RHEL/UBI; the docs lean
Debian-family but it isn't required. Worth challenging before mlowcher's
role lands and the choice ossifies.

**RHDP environment lifetime vs "leave Tier 1 up permanently."** RHDP
open envs are time-bounded (typically 24-72h, extendable). "Leave
networking up permanently" doesn't survive an RHDP teardown. Either
define the rebuild story for Tier 1 after RHDP expiry or stop calling
it "permanent."

**Per-SE isolation is enforced by vault discipline, not by code.** S3
bucket name comes from `my_s3_bucket_name` in the remote vault, AAP org
and inventory names are hardcoded. If an SE copies a teammate's remote
vault to bootstrap quickly, they'll collide on bucket names. Worth a
hash-of-SE-username default and an explicit assertion that the bucket
name includes the SE identity.

---

## 3. Sequencing dependencies the phase plan ignores

- **Vault → AAP CaC.** The Vault demo story isn't "install Vault." It's
  "AAP credential type wired to a Vault path, used by a job template."
  That's an `infra.aap_configuration` change, not a Vault role change.
  Phase 2 item 6 implies one but plans the other.
- **AD LDAP → Vault LDAP auth.** If you want the Vault demo to
  authenticate via AD users, AD must be stable first. PLANNING.md
  sequences AD and Vault into the same phase without acknowledging the
  coupling.
- **IdM-AD trust** has real DNS prerequisites (SRV records, two-way
  conditional forwarders, time sync, forest-functional level).
  Internal-only `dc1.lab` makes this fiddly. Add a spike before
  committing to Phase 3 item 9.
- **Bootstrap contract.** `aap.as.code` creates *something* that DC1
  then consumes. PLANNING.md does not describe the contract: what
  objects (org name, inventory name, project, credential types, EE)
  does the bootstrap guarantee? Without that interface written down,
  every change to either repo can break the other silently.

---

## 4. Missing from the prioritized work list

Add to Phase 1, before bug fixes:

- **Lint + CI baseline.** `ansible-lint`, `yamllint`,
  `terraform fmt/validate`, GitHub Actions on PR. The cockpit
  contradiction (bug 6) is the canonical "ansible-lint would have caught
  this" example. Free regressions guard for everything that follows.
- **Pre-commit hooks** mirroring CI, so engineers don't push red builds.
- **A minimal molecule scaffold** for `linux_post_install` and `rhsm`,
  the two roles every node will inherit. Do not add molecule for
  everything — start with the shared base.
- **Cost guardrail.** AWS Budgets alert at $X/day per SE account, plus
  an auto-stop Lambda or EventBridge rule for instances tagged
  `auto-stop=true`. "Stop, don't terminate" is policy; without
  enforcement it becomes "leave it running by accident."
- **Source-of-truth ownership.** You now have CLAUDE.md (project),
  CLAUDE.md (global), PLANNING.md, ROADMAP.md (other repo), GitHub
  Issues, and memory. Add a one-paragraph "where does X live" note.
  Today, the architecture status table appears in three places and
  disagrees with itself (CLAUDE.md says Satellite "Complete";
  PLANNING.md flags a Blocking manifest bug).

Add to Open Questions:

- What does `aap.as.code` guarantee to DC1? (Names, credentials, EEs.)
- How does Tier 1 networking survive an RHDP environment teardown?
- What's the recovery path when a stopped EBS-backed instance fails to
  come up clean?
- What's the long-term home for Vault unseal keys?

---

## 5. Smaller things worth fixing in the docs themselves

- "Resolved Decisions" lists `dc1.lab` with a partially incorrect
  rationale (see §2).
- "Migration Sequence" marks Satellite "Migrated" while Known Bugs marks
  the manifest "Blocking." Pick one.
- Architecture table in CLAUDE.md says Vault, IdM are absent;
  PLANNING.md adds them. Sync.
- "infrastructure role shows the pattern — token created in `always:`"
  — either fix the code to match or fix the doc to match the code.
  Right now it documents an aspiration as a fact.

---

## Bottom line

The plan's *goals* are sound. The *foundation* it claims to be building
on (token hygiene, ansible.platform-only, repeatable Terraform, per-SE
isolation) is partially fictional in the current code. Phase 1 should
be honest about that — fix the foundation **and** establish CI to keep
it fixed — before any new layer goes on top.
