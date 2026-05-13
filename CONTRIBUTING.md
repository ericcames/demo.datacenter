# Contributing

## Workflow

**Every change follows this sequence — no exceptions:**

```
Open issue → branch from main → implement → open PR (Closes #N) → merge → issue closes
```

1. **Open an issue first** — before writing a single line of code or making any change, open a GitHub issue describing what you're fixing or adding and why. No implementation without an issue.
2. **Branch from `main`** — use the naming pattern `<type>/<short-description>` (e.g. `fix/satellite-manifest`, `feat/f5-role`, `docs/planning-update`).
3. **One concern per PR** — group changes by shared root cause, not item count. The test: would you revert these together? If yes, ship them together. Behavior changes stay isolated regardless.
4. **Reference the issue** — include `Closes #<number>` in your PR description so the issue closes automatically on merge.
5. **PRs target `main`** — direct pushes to `main` are not blocked, but all non-trivial changes should go through a PR for traceability.
6. **Update CHANGELOG.md** — every PR must include a CHANGELOG entry grouped under Added / Changed / Fixed / Removed.

## Branch naming

| Prefix | When to use |
|--------|-------------|
| `feat/` | New capability or role |
| `fix/` | Bug fix |
| `docs/` | Documentation only |
| `chore/` | Dependency updates, CI, housekeeping |
| `refactor/` | Code restructure with no behavior change |

## Commit messages

```
<type>: <short description>

<optional body explaining why, not what>
```

Types: `feat`, `fix`, `docs`, `refactor`, `chore`

## Code conventions

See [CLAUDE.md](CLAUDE.md) for full detail. Key rules:

- **`ansible.platform` over `ansible.controller`** — `ansible.controller` is legacy; never use it in new code
- **Always delete tokens** — any playbook that creates an AAP token via `ansible.platform.token` must delete it in an `always:` block
- **Remote vault for secrets** — never commit credentials; use the `remote_vault` role to load secrets at runtime from `{{ my_remote_vault }}`
- **Layer order matters** — Layer 0 (Terraform) must be solid before Layer 1 work; Layer 1 before Layer 2, etc. Don't build on an unstable foundation
- **RHEL only** — all Linux hosts use CIS-hardened RHEL 9 from `image.builder.pipeline`; no Ubuntu or other distros

## Testing

Infrastructure changes should be tested with `terraform plan` at minimum and `terraform apply`+`destroy` where feasible. Ansible role changes should be tested against a real AAP job template run. Document what you ran in the PR description.

## Sensitive data

Never commit:

- Credentials, tokens, or passwords of any kind
- `.envrc` (contains AWS credentials — copy from `.envrc.example`)
- Terraform state files (`*.tfstate`) — state lives in S3
- `terraform_cli/scripts/win25_userdata` (Windows setup script)

See [SECURITY.md](.github/SECURITY.md) for the full list.
