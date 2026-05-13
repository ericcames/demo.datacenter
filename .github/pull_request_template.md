## Summary

<!-- What does this PR change and why? -->

## Testing

<!-- How was this tested? Which playbook(s) or terraform commands did you run?
     For infrastructure changes: did terraform plan/apply complete cleanly?
     For Ansible role changes: did the job template run green end-to-end? -->

## Checklist

- [ ] CHANGELOG.md updated (Added / Changed / Fixed / Removed)
- [ ] No credentials, tokens, inventory files, or state files committed
- [ ] New Ansible tasks use `ansible.platform` (not `ansible.controller`)
- [ ] Any token created in a playbook is deleted in an `always:` block

## Related Issues

<!-- Closes #<issue number> -->
