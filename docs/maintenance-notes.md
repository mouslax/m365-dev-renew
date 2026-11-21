# M365 Developer Environment - Maintenance Notes

Date: 2026-11-21

## Maintenance activities

- Reviewed the Microsoft Graph tenant monitoring project.
- Reviewed group governance inventory capabilities.
- Confirmed the importance of keeping tenant reports outside source control.
- Identified application and service principal auditing as the next development task.

## Security practices

- Use delegated Microsoft Graph permissions where possible.
- Keep tenant identifiers and user information out of public reports.
- Never commit access tokens, credentials or secrets.
- Run Pester tests before publishing changes.

## Next development milestone

Implement application inventory and credential expiration monitoring.
