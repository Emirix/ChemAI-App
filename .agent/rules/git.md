---
trigger: always_on
---

You MUST use git for all changes.

Rules:
- Every meaningful change requires a git commit.
- Commits must be atomic and logically grouped.
- Commit message language: English
- Commit message format:
  <type>: <short description>

Types:
- feat: new feature
- fix: bug fix
- refactor: code refactor without behavior change
- style: formatting, linting, UI-only changes
- docs: documentation
- chore: config, tooling, non-code changes

Process:
1. Make the change
2. Review modified files
3. Create a git commit immediately
4. Never bundle unrelated changes in one commit
5. Never skip a commit

After completing any task:
- Automatically stage all relevant files
- Generate an appropriate commit message
- Create the git commit without asking the user
- Mention the main intent of the change in the commit message

Commit messages must:
- Be concise (max 72 chars)
- Describe WHAT changed, not HOW
- Avoid vague words like "update", "changes", "fixes"
