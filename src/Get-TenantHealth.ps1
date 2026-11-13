#requires -Version 7.0

function Get-GraphCollection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Uri
    )

    $items = [System.Collections.Generic.List[object]]::new()
    $nextUri = $Uri

    while ($nextUri) {
        $response = Invoke-MgGraphRequest `
            -Method GET `
            -Uri $nextUri `
            -OutputType PSObject

        foreach ($item in @($response.value)) {
            if ($null -ne $item) {
                $items.Add($item)
            }
        }

        $nextUri = $response.'@odata.nextLink'
    }

    return $items.ToArray()
}

function Get-M365TenantHealth {
    [CmdletBinding()]
    param()

    $context = Get-MgContext
    if (-not $context) {
        throw "No hay una sesión de Microsoft Graph. Ejecuta Connect-MgGraph primero."
    }

    $organization = Get-GraphCollection `
        -Uri 'https://graph.microsoft.com/v1.0/organization?$select=id,displayName'

    $users = Get-GraphCollection `
        -Uri 'https://graph.microsoft.com/v1.0/users?$select=id,accountEnabled,userType&$top=999'

    $skus = Get-GraphCollection `
        -Uri 'https://graph.microsoft.com/v1.0/subscribedSkus'

    $enabledUsers = @($users | Where-Object { $_.accountEnabled -eq $true }).Count
    $disabledUsers = @($users | Where-Object { $_.accountEnabled -eq $false }).Count
    $guestUsers = @($users | Where-Object { $_.userType -eq 'Guest' }).Count

    $licenseSummary = foreach ($sku in $skus) {
        $enabledUnits = [int]$sku.prepaidUnits.enabled
        $consumedUnits = [int]$sku.consumedUnits

        [PSCustomObject]@{
            SkuPartNumber = $sku.skuPartNumber
            Status        = $sku.capabilityStatus
            Consumed      = $consumedUnits
            Available     = [Math]::Max(0, ($enabledUnits - $consumedUnits))
        }
    }

    [PSCustomObject]@{
        GeneratedAt  = (Get-Date).ToString('o')
        Organization = $organization[0].displayName
        TotalUsers   = $users.Count
        EnabledUsers = $enabledUsers
        DisabledUsers = $disabledUsers
        GuestUsers   = $guestUsers
        Licenses     = @($licenseSummary)
    }
}
