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
  queryName:   # User-friendly query title used when creating/storing queries in Azure DevOps UI
  query: |    # WIQL query that selects the work items in scope

policy:
  rules:      # One or more conditions evaluated against the query result
    - id:
      description:
      mustBeInQueryResults:  # boolean: false => item must NOT be in query results, true => item must be in query results
  severity:   # critical | high | medium | low
  action:     # block | warn | notify
```

### `source.query`

A standard [Azure DevOps WIQL](https://learn.microsoft.com/en-us/azure/devops/boards/queries/wiql-syntax) query.  
The query **must** include `SELECT` and `FROM WorkItems` at minimum.

### Policy evaluation model

The policy engine evaluates templates using the boolean `mustBeInQueryResults` rule property:

- `mustBeInQueryResults: false` means a work item **must not** be in query results.
- `mustBeInQueryResults: true` means a work item **must** be in query results.
- Design each template query accordingly:
  - violation query + `mustBeInQueryResults: false`
  - compliance query + `mustBeInQueryResults: true`

## Available templates

| File | Description |
|------|-------------|
| [`no-critical-bugs.yml`](no-critical-bugs.yml) | Blocks delivery when open critical bugs exist |
| [`no-overdue-work-items.yml`](no-overdue-work-items.yml) | Warns when any active work item has passed its target date |
| [`required-fields-on-active-items.yml`](required-fields-on-active-items.yml) | Ensures active work items have mandatory fields populated |
| [`active-backlog-items-must-have-estimates.yml`](active-backlog-items-must-have-estimates.yml) | Flags active backlog items and bugs with missing/non-positive estimates |
| [`backlog-items-must-have-parent.yml`](backlog-items-must-have-parent.yml) | Flags backlog-level items that are missing a parent |
| [`backlog-items-parent-must-be-feature.yml`](backlog-items-parent-must-be-feature.yml) | Flags requirement/bug items linked under non-feature parents |
| [`features-parent-must-be-epic.yml`](features-parent-must-be-epic.yml) | Flags features linked under non-epic parents |
| [`pull-request-linked-items-must-use-allowed-types.yml`](pull-request-linked-items-must-use-allowed-types.yml) | Blocks when linked PR work items are outside approved type groups |
| [`recently-changed-items-in-team-area.yml`](recently-changed-items-in-team-area.yml) | Team-area scoped recent changes template (requires team descriptor customization) |
| [`tasks-parent-must-be-backlog-item-or-bug.yml`](tasks-parent-must-be-backlog-item-or-bug.yml) | Flags task items linked under invalid parent types |
| [`work-items-must-not-use-project-root-area.yml`](work-items-must-not-use-project-root-area.yml) | Flags work items that remain on the project root area path |

## Adding a new template

1. Create a new `.yml` file in this folder following the structure above.
2. Test the WIQL query in Azure DevOps Boards → Queries before committing.
3. Open a pull request following the guidelines in [CONTRIBUTING.md](../CONTRIBUTING.md).
