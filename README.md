# PolicyVault Policy Templates

A collection of reusable policy templates for [PolicyVault](https://github.com/PolicyVault). These templates provide a starting point for defining work-item–based policies that can be imported directly into PolicyVault.

## Overview

Policies in this repository are based on **work item queries** — they use the native query language of the underlying issue-tracking platform to select a set of work items, and then enforce conditions (thresholds, field checks, SLA rules, etc.) against those items.

### Currently supported platforms

| Platform | Type | Folder |
|----------|------|--------|
| Azure DevOps | Work Item Query Language (WIQL) | [`azure-devops/`](azure-devops/) |

### Planned future platforms

- **GitHub Issues** — filter-based policies using GitHub's issue search syntax
- **Atlassian Jira** — JQL (Jira Query Language) based policies

Each template is designed to be copied, customised, and then imported into a PolicyVault instance.

## Usage

1. Browse the platform folder that matches your issue-tracking tool.
2. Copy the template that best matches your use-case.
3. Customise the `query`, thresholds, and metadata fields to fit your requirements.
4. Import the customised template into PolicyVault.

## Release automation

GitHub Actions validates the repository's template YAML files and performs basic WIQL sanity checks on every pull request and push to `main`. Pushes to `main` also calculate a release version with GitVersion, tag releases from `majorMinorPatch` so the patch number advances on each new release, create a GitHub release for the tagged repository state, and upload each template YAML file as an explicit release asset for direct programmatic download.

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

## Security

For responsible disclosure of security vulnerabilities, please refer to [SECURITY.md](SECURITY.md).

## License

This project is licensed under the [MIT License](LICENSE).