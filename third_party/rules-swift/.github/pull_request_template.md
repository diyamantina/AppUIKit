<!-- One focused change per PR (git-discipline.md Rule 3.1). Split unrelated concerns. -->

## What this changes

<!-- One paragraph: the change and why. Reference files by symbol or name, not by line number. -->

## Linked issue

<!-- Closes #N for a bug fix (issue-first workflow, Rule 4.3). Omit only for a trivial docs/tooling change with no issue. -->
Closes #

## Checklist

- [ ] One cohesive change; unrelated concerns are in separate PRs (Rule 3.1).
- [ ] `CHANGELOG.md` updated if production source changed; otherwise `[no-changelog]` is justified (Rule 3.2).
- [ ] Self-critic pass done: I read my own diff as a reviewer and fixed what it surfaced (Rule 3.3).
- [ ] No AI/tool attribution and no em dashes in any committed text (Rules 5.1, 5.2).
- [ ] Gates pass locally: `sh scripts/leak-gate.sh` and `sh scripts/check-namespacing.sh` are green.
