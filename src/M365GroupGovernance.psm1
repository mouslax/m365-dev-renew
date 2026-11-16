function Get-M365GroupGovernance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$GetGroups,

        [Parameter(Mandatory)]
        [scriptblock]$GetOwners
    )

    $groups = @(& $GetGroups)

    foreach ($group in $groups) {
        $owners = @(& $GetOwners $group.id)

        [pscustomobject]@{
            GroupId         = $group.id
            DisplayName     = $group.displayName
            Description     = $group.description
            Visibility      = $group.visibility
            GroupTypes      = (@($group.groupTypes) -join ",")
            MailEnabled     = $group.mailEnabled
            SecurityEnabled = $group.securityEnabled
            OwnerCount      = $owners.Count
            Owners          = (@($owners | ForEach-Object {
                if ($_.displayName) { $_.displayName }
                else { $_.id }
            }) -join "; ")
            AuditStatus     = if ($owners.Count -eq 0) {
                "ReviewRequired"
            } else {
                "HasOwner"
            }
        }
    }
}

Export-ModuleMember -Function Get-M365GroupGovernance
