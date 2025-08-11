# stitch.OS

This is the main README file for the stitch.OS project.

## Project Workflows

*   [Whiteboard 3.0 Workflow](PLACEHOLDER_PATH_TO_WHITEBOARD_3.0_FOLDER_OR_DOCS)

Please replace `PLACEHOLDER_PATH_TO_WHITEBOARD_3.0_FOLDER_OR_DOCS` with the actual location of your whiteboard 3.0 folder or its documentation. This could be a relative path within the project, or a URL if it's hosted elsewhere (like a wiki or a cloud drive).

## ClickUp Data

Run the ClickUp sync script to populate `clickup/data/` and regenerate `clickup/WORKFLOW.md`:

```bash
CLICKUP_TOKEN=<token> CLICKUP_TEAM_ID=<team_id> node scripts/sync_clickup.js
```

This fetches the latest spaces, folders, lists, and tasks for StitchOS.

## Terms and Conditions

Use of this repository is governed by the [TERMS.md](TERMS.md) agreement.
