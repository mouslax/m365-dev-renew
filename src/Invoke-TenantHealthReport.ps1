#requires -Version 7.0
#requires -Modules Microsoft.Graph.Authentication

$ErrorActionPreference = "Stop"

$Repo = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "Get-TenantHealth.ps1")

$requiredScopes = @(
    "Organization.Read.All",
    "User.Read.All"
)

Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes $requiredScopes -NoWelcome

Write-Host "Collecting tenant information..." -ForegroundColor Cyan
$report = Get-M365TenantHealth

$outputDirectory = Join-Path $HOME "Documents\M365-Tenant-Reports"
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jsonPath = Join-Path $outputDirectory "tenant-health-$timestamp.json"
$csvPath = Join-Path $outputDirectory "tenant-licenses-$timestamp.csv"

$report | ConvertTo-Json -Depth 8 |
    Set-Content -Path $jsonPath -Encoding utf8

$report.Licenses |
    Export-Csv -Path $csvPath -NoTypeInformation -Encoding utf8

Write-Host ""
Write-Host "TENANT HEALTH REPORT" -ForegroundColor Green
$report |
    Select-Object GeneratedAt, Organization, TotalUsers,
        EnabledUsers, DisabledUsers, GuestUsers |
    Format-List

Write-Host "License report:"
$report.Licenses | Format-Table -AutoSize

Write-Host "Reports saved outside the repository:"
Write-Host $outputDirectory
