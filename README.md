# github-release-notes
GitHub Release Notes preparation from commit messages

Usage:
```yaml
- name: Prepare Release Notes
  uses: lyskouski/github-release-notes@v1
  id: notes
  with:
    version: '0.0.6'

- name: Show Release Notes
  run: echo "${{ steps.notes.outputs.release_notes }}"
```

**Name Conventions:**
[#{ticket number}] [{category}] issue name. short description


| Category | Description |
| ---- | ---- |
| AD | Architecture Description Records |
| BF | Bug Fix |
| BP | Build Process improvements (CI/CD Change) |
| CI | Critical Issue |
| CR | Change Request |
| DC | Documentation Change |
| NF | New Functionality |
| RF | Refactoring |

**Sample:** [#1] [NF] Initialization. Adjust script
