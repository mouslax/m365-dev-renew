BeforeAll {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    . (Join-Path $PSScriptRoot "../src/Get-TenantHealth.ps1")
}

Describe "Get-M365TenantHealth" {
    It "rejects a request without a Graph session" {
        Mock Get-MgContext { $null }

        { Get-M365TenantHealth } | Should -Throw "*No hay una sesión*"
    }

    It "calculates user and license inventory" {
        Mock Get-MgContext {
            [PSCustomObject]@{ TenantId = "test-tenant" }
        }

        Mock Get-GraphCollection -ParameterFilter {
            $Uri -match "/organization"
        } {
            @([PSCustomObject]@{ displayName = "Contoso Test" })
        }

        Mock Get-GraphCollection -ParameterFilter {
            $Uri -match "/users"
        } {
            @(
                [PSCustomObject]@{ accountEnabled = $true;  userType = "Member" }
                [PSCustomObject]@{ accountEnabled = $true;  userType = "Guest" }
                [PSCustomObject]@{ accountEnabled = $false; userType = "Member" }
            )
        }

        Mock Get-GraphCollection -ParameterFilter {
            $Uri -match "/subscribedSkus"
        } {
            @(
                [PSCustomObject]@{
                    skuPartNumber = "TEST_E5"
                    capabilityStatus = "Enabled"
                    consumedUnits = 8
                    prepaidUnits = [PSCustomObject]@{ enabled = 10 }
                }
            )
        }

        $result = Get-M365TenantHealth

        $result.Organization | Should -Be "Contoso Test"
        $result.TotalUsers | Should -Be 3
        $result.EnabledUsers | Should -Be 2
        $result.DisabledUsers | Should -Be 1
        $result.GuestUsers | Should -Be 1
        $result.Licenses[0].Consumed | Should -Be 8
        $result.Licenses[0].Available | Should -Be 2
    }
}

Describe "Get-GraphCollection" {
    It "follows Graph pagination links" {
        Mock Invoke-MgGraphRequest -ParameterFilter {
            $Uri -eq "https://graph.test/page1"
        } {
            [PSCustomObject]@{
                value = @([PSCustomObject]@{ id = "one" })
                AdditionalProperties = @{}
                '@odata.nextLink' = "https://graph.test/page2"
            }
        }

        Mock Invoke-MgGraphRequest -ParameterFilter {
            $Uri -eq "https://graph.test/page2"
        } {
            [PSCustomObject]@{
                value = @([PSCustomObject]@{ id = "two" })
            }
        }

        $result = @(Get-GraphCollection -Uri "https://graph.test/page1")

        $result.Count | Should -Be 2
        $result[0].id | Should -Be "one"
        $result[1].id | Should -Be "two"
        Should -Invoke -CommandName Invoke-MgGraphRequest -Times 2
    }
}
