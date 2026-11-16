$ErrorActionPreference = "Stop"

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module "$PSScriptRoot/M365GroupGovernance.psm1" -Force

$requiredScopes = @(
    "Group.Read.All",
    "GroupMember.Read.All"
)

$context = Get-MgContext
$missingScopes = @($requiredScopes | Where-Object {
    $_ -notin @($context.Scopes)
})

if (-not $context -or $missingScopes.Count -gt 0) {
    if ($context) {
        Disconnect-MgGraph | Out-Null
    }

    Connect-MgGraph -Scopes @(
        "Organization.Read.All",
        "User.Read.All",
        "Group.Read.All",
        "GroupMember.Read.All"
    )
}

function Get-GraphPagedCollection {
    param([Parameter(Mandatory)][string]$Uri)

    $items = [System.Collections.Generic.List[object]]::new()

    while ($Uri) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $Uri
        foreach ($item in @($response.value)) {
            $items.Add($item)
        }
        $Uri = $response.'@odata.nextLink'
    }

    return $items.ToArray()
}

$groupProvider = {
    $uri = 'https://graph.microsoft.com/v1.0/groups?$select=id,displayName,description,groupTypes,mailEnabled,securityEnabled,visibility&$top=100'
    Get-GraphPagedCollection -Uri $uri
}

$ownerProvider = {
    param($groupId)
    $uri = "https://graph.microsoft.com/v1.0/groups/$groupId/owners?`$select=id,displayName,userPrincipalName&`$top=100"
    Get-GraphPagedCollection -Uri $uri
}

Write-Host "`nEjecutando auditoría de gobernanza..." -ForegroundColor Cyan

$inventory = @(
    Get-M365GroupGovernance -GetGroups $groupProvider -GetOwners $ownerProvider
)

$outputDirectory = "$HOME\Documents\M365-Tenant-Reports"
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$jsonFile = Join-Path $outputDirectory "GroupAudit-$timestamp.json"
$csvFile = Join-Path $outputDirectory "GroupAudit-$timestamp.csv"

$summary = [pscustomobject]@{
    GeneratedAt = (Get-Date).ToUniversalTime().ToString("o")
    TotalGroups = $inventory.Count
    GroupsWithOwners = @($inventory | Where-Object OwnerCount -gt 0).Count
    GroupsWithoutOwners = @($inventory | Where-Object OwnerCount -eq 0).Count
    Groups = $inventory
}

$summary | ConvertTo-Json -Depth 10 |
    Set-Content -Path $jsonFile -Encoding utf8

$inventory | Export-Csv -Path $csvFile -NoTypeInformation -Encoding utf8

$summary | Select-Object GeneratedAt,TotalGroups,GroupsWithOwners,GroupsWithoutOwners |
    Format-List

Write-Host "JSON: $jsonFile"
Write-Host "CSV:  $csvFile"
