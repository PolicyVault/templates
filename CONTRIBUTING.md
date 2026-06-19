# Contributing to PolicyVault Templates

Thank you for your interest in contributing to **PolicyVault Templates**! The guidelines below help keep the repository organised and the review process smooth for everyone.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Branch Naming Conventions](#branch-naming-conventions)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Review Process](#review-process)

---

## Code of Conduct

By participating in this project, you agree to abide by the [Contributor Covenant Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). Please treat all participants with respect.

---

## Getting Started

1. **Fork** the repository and **clone** your fork locally.
2. Create a new branch following the [branch naming conventions](#branch-naming-conventions) below.
3. Make your changes, then **push** the branch to your fork.
4. Open a **Pull Request** against the `main` branch of this repository.

> **Direct pushes to `main` are not allowed.** All changes must go through a pull request and pass review before being merged.

---

## Branch Naming Conventions

Branch names must follow this pattern:

```
<type>/<short-description>
```

| Type | When to use |
|------|-------------|
| `feat` | Adding a new policy template or feature |
| `fix` | Fixing an error in an existing template |
| `docs` | Documentation-only changes |
| `chore` | Maintenance tasks (CI, tooling, dependencies) |
| `refactor` | Restructuring templates without changing their meaning |

### Rules

- Use **lowercase letters**, **numbers**, and **hyphens** only — no spaces or underscores.
- Keep the description **short and descriptive** (3–5 words is ideal).
- Examples of valid branch names:
  - `feat/add-data-retention-policy`
  - `fix/correct-rbac-template-typo`
  - `docs/update-contributing-guide`
  - `chore/add-gitignore`
  - `refactor/reorganise-access-control`

---

## Submitting a Pull Request

1. Ensure your branch is up to date with `main` before opening the PR.
2. Open a pull request from your branch to `main`.
3. Fill in the pull request template (if provided) with:
   - **What** the change does.
   - **Why** the change is needed.
   - Any relevant **issue numbers** (e.g. `Closes #42`).
4. Make sure all automated checks pass before requesting a review.
5. Request a review from at least one maintainer.

---

## Review Process

- A maintainer will review your pull request as soon as possible.
- You may be asked to make changes — please address all review comments.
- Once approved, a maintainer will merge the pull request.
- Merges use **squash-and-merge** to keep the commit history clean.

---

Thank you for helping improve PolicyVault Templates! 🎉
