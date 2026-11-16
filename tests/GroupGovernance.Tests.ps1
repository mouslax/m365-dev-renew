BeforeAll {
    Import-Module "$PSScriptRoot/../src/M365GroupGovernance.psm1" -Force
}

Describe "Get-M365GroupGovernance" {
    It "Returns group information and its owners" {
        $groups = {
            @(
                [pscustomobject]@{
                    id = "group-1"
                    displayName = "Engineering"
                    description = "Engineering team"
                    visibility = "Private"
                    groupTypes = @("Unified")
                    mailEnabled = $true
                    securityEnabled = $false
                }
            )
        }

        $owners = {
            param($id)
            @(
                [pscustomobject]@{
                    id = "user-1"
                    displayName = "Owner One"
                }
            )
        }

        $result = @(Get-M365GroupGovernance -GetGroups $groups -GetOwners $owners)

        $result.Count | Should -Be 1
        $result[0].DisplayName | Should -Be "Engineering"
        $result[0].OwnerCount | Should -Be 1
        $result[0].AuditStatus | Should -Be "HasOwner"
    }

    It "Flags groups without owners for review" {
        $groups = {
            @(
                [pscustomobject]@{
                    id = "group-2"
                    displayName = "Orphan Group"
                    description = ""
                    visibility = "Private"
                    groupTypes = @()
                    mailEnabled = $false
                    securityEnabled = $true
                }
            )
        }

        $owners = { param($id) @() }

        $result = @(Get-M365GroupGovernance -GetGroups $groups -GetOwners $owners)

        $result[0].OwnerCount | Should -Be 0
        $result[0].AuditStatus | Should -Be "ReviewRequired"
    }

    It "Returns an empty result when there are no groups" {
        $groups = { @() }
        $owners = { param($id) @() }

        $result = @(Get-M365GroupGovernance -GetGroups $groups -GetOwners $owners)

        $result.Count | Should -Be 0
    }
}
