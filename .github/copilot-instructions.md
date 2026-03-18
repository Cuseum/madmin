# GitHub Copilot Instructions

## Pull Request Titles and Descriptions

When working on a pull request, always maintain a comprehensive PR title and description that accurately reflects **all** changes in the PR, not just the most recent ones.

### PR Title
- The title should be a concise, high-level summary of the overall goal or feature being implemented by the PR.
- Do **not** replace the title with a description of only the latest change you made. Keep the title focused on the PR's overall purpose.

### PR Description
- The description must always be a complete summary of **everything** that has been changed in the PR from start to finish.
- When adding new changes to an existing PR, update the description to incorporate those changes into the existing summary — do not replace the whole description with only the latest change.
- Structure the description with a high-level summary and a checklist of completed work items, so it is easy to understand the full scope of the PR at a glance.
- Use the `report_progress` tool's `prDescription` parameter to maintain this running checklist throughout the session.
