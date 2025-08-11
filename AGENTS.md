# StitchOS ClickUp Repo Agent

## Overview

This agent maintains automated documentation from ClickUp exports, focusing on:

- Refreshing workflow documentation
- Generating reports
- Opening precise PRs

## Data Sources

- `clickup/data/**`: JSON exports (authoritative source)
    - spaces.json
    - folders.json
    - lists.json
    - tasks/<list_id>.json

## Outputs

1. `clickup/WORKFLOW.md`: Main workflow document
2. `reports/daily/YYYY-MM-DD.md`: Daily reports
3. `reports/weekly/YYYY-WW.md`: Weekly reports

## Commands

- `Refresh docs`: Update WORKFLOW.md
- `Daily report for <date>`: Generate/update daily report
- `Weekly report for <YYYY-WW>`: Generate/update weekly report
- `Find blockers`: List blocking issues
- `Triage 10 oldest overdue`: Action list by assignee
- `Prepare release notes`: Summarize completed work

## PR Guidelines

- Branch: `chore/clickup-refresh-YYYYMMDD-HHMM`
- Title: `docs: refresh ClickUp workflow (YYYY-MM-DD HH:mm)`
- Labels: `automation`, `docs`
- Required checks:
    - JSON timestamp validation
    - No secrets/tokens
    - Limited file scope

## Quality Standards

- Idempotent updates
- Privacy-conscious
- Performance-optimized
- Date-safe parsing
- Executive-friendly tone

## Merge Error Resolution

If merge errors occur:
1. Verify JSON data integrity in `clickup/data/**`
2. Check template variable syntax `{{VARIABLE}}`
3. Ensure tables have proper column alignment
4. Look for HTML comments with error details
5. Validate timestamp formats

## Debug Commands
- `Verify JSON`: Check data file integrity
- `Test merge`: Dry-run merge without commits
- `Show variables`: Display all template variables

*Last updated: {{DATE}}*
