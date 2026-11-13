# M365 Tenant Health Monitor

A PowerShell 7 project for collecting Microsoft 365 tenant health and
license inventory data through Microsoft Graph.

## Features

- Reads organization information from Microsoft Graph.
- Retrieves users with pagination.
- Counts enabled, disabled and guest accounts.
- Summarizes subscribed SKU capacity and consumption.
- Exports timestamped JSON and CSV reports.
- Stores reports outside the source repository.

## Requirements

- PowerShell 7.0 or later.
- A Microsoft 365 developer or test tenant.
- Microsoft Graph PowerShell Authentication module.
- Delegated permissions:
  - `Organization.Read.All`
  - `User.Read.All`

Install the authentication module:

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
```

## Run

From the repository root:

```powershell
pwsh -File .\src\Invoke-TenantHealthReport.ps1
```

Sign in when Microsoft Graph prompts you for authentication.

## Output

Reports are written to:

`~/Documents/M365-Tenant-Reports`

Tenant reports are deliberately excluded from Git to avoid publishing
organization data.

## Project layout

```text
src/
  Get-TenantHealth.ps1
  Invoke-TenantHealthReport.ps1
tests/
README.md
.gitignore
```

## Limitations

This is an inventory and reporting tool, not a complete security audit.
It does not modify users, licenses, groups or tenant configuration.

Graph permissions and tenant policies may affect which information
can be retrieved.
