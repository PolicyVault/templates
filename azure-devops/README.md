# Azure DevOps – Work Item Query Policy Templates

This folder contains PolicyVault policy templates that use **Azure DevOps Work Item Query Language (WIQL)** to select work items and enforce conditions against them.

## Template structure

Each template is a YAML file with the following top-level sections:

```yaml
apiVersion: policyvault.io/v1
kind: WorkItemQueryPolicy
metadata:
  name:        # Unique identifier (kebab-case)
  title:       # Human-readable title
  description: # What the policy enforces and why
  tags:        # Free-form tags for discovery

source:
  platform: azure-devops
  query: |    # WIQL query that selects the work items in scope

policy:
  rules:      # One or more conditions evaluated against the query result
    - id:
      description:
      condition:  # max_count | min_count | field_equals | field_not_empty
      ...
  severity:   # critical | high | medium | low
  action:     # block | warn | notify
```

### `source.query`

A standard [Azure DevOps WIQL](https://learn.microsoft.com/en-us/azure/devops/boards/queries/wiql-syntax) query.  
The query **must** include `SELECT` and `FROM WorkItems` at minimum.

### `policy.rules[].condition`

| Condition | Required extra fields | Description |
|-----------|-----------------------|-------------|
| `max_count` | `threshold` | Fails if the query returns more than `threshold` items |
| `min_count` | `threshold` | Fails if the query returns fewer than `threshold` items |
| `field_equals` | `field`, `value` | Fails if any returned item has `field` ≠ `value` |
| `field_not_empty` | `field` | Fails if any returned item has an empty `field` |

## Available templates

| File | Description |
|------|-------------|
| [`no-critical-bugs.yml`](no-critical-bugs.yml) | Blocks delivery when open critical bugs exist |
| [`no-overdue-work-items.yml`](no-overdue-work-items.yml) | Warns when any active work item has passed its target date |
| [`required-fields-on-active-items.yml`](required-fields-on-active-items.yml) | Ensures active work items have mandatory fields populated |

## Adding a new template

1. Create a new `.yml` file in this folder following the structure above.
2. Test the WIQL query in Azure DevOps Boards → Queries before committing.
3. Open a pull request following the guidelines in [CONTRIBUTING.md](../CONTRIBUTING.md).
