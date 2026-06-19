# Security Policy

## Supported Versions

The following table lists which versions of PolicyVault Templates currently receive security fixes.

| Version | Supported |
|---------|-----------|
| `main`  | ✅ Yes    |

---

## Reporting a Vulnerability

We take security seriously. If you discover a vulnerability in this repository or in the templates it contains, please follow responsible disclosure practices:

1. **Do not open a public GitHub issue.** Public disclosure before a fix is available may put users at risk.
2. **Email us** at **security@policyvault.io** with:
   - A clear description of the vulnerability.
   - Steps to reproduce or a proof-of-concept (if applicable).
   - The potential impact and affected templates or files.
3. You will receive an **acknowledgement within 48 hours**.
4. We aim to provide a fix or mitigation **within 14 days** of confirmed reproduction.
5. Once the fix is released, we will coordinate with you on a **public disclosure date** and credit you in the release notes (unless you prefer to remain anonymous).

---

## Scope

This policy covers:

- Policy templates stored in this repository that could lead to privilege escalation, data exposure, or other security issues when deployed in a PolicyVault instance.
- Configuration files or scripts in this repository that introduce a security risk.

Out of scope:

- Vulnerabilities in PolicyVault itself (please report those to the PolicyVault core repository).
- Third-party dependencies — please report these directly to the respective project.

---

## Security Best Practices for Templates

When using or customising templates from this repository:

- Always review a template before applying it to a production environment.
- Apply the **principle of least privilege** — grant only the permissions actually required.
- Regularly audit applied policies against your organisation's current requirements.
- Keep your PolicyVault instance up to date to benefit from the latest security patches.
