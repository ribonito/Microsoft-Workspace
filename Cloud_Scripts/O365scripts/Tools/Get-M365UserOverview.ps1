<#
.SYNOPSIS
    Generates an inventory and overview of Microsoft 365 user accounts and licensing status.

.DESCRIPTION
    Queries user directory objects via Microsoft Graph PowerShell or Entra ID / MSOnline,
    extracting user identities, sign-in states, assigned license SKUs, department, and
    mailbox creation dates. Supports optional export to CSV.

.PARAMETER ExportPath
    Optional file path to output results to a CSV report.

.PARAMETER EnabledOnly
    Switch to filter results for only enabled user accounts.

.EXAMPLE
    Get-M365UserOverview
    Displays user account overview in the console.

.EXAMPLE
    Get-M365UserOverview -ExportPath "$env:USERPROFILE\Desktop\M365Users.csv" -EnabledOnly
    Exports all active enabled user accounts to a CSV report.

.OUTPUTS
    [PSCustomObject]
    Structured objects representing user attributes, license state, and department.

.NOTES
    Author: Josep Canas - M365 Solutions Architect
    Product: Microsoft 365 Administrative Tools
    Requires Microsoft.Graph.Users or AzureAD module.

.LINK
    https://learn.microsoft.com/powershell/microsoftgraph/overview
    https://learn.microsoft.com/graph/api/user-list
#>
function Get-M365UserOverview {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Destination path for CSV export.")]
        [string]$ExportPath,

        [Parameter(Mandatory = $false, HelpMessage = "Filter to return only active enabled accounts.")]
        [switch]$EnabledOnly
    )

    process {
        Write-Host "Querying Microsoft 365 user directory..." -ForegroundColor Cyan

        $Users = $null
        if (Get-Command -Name Get-MgUser -ErrorAction SilentlyContinue) {
            # Preferred: Microsoft Graph PowerShell
            $filter = if ($EnabledOnly) { "accountEnabled eq true" } else { $null }
            $Users = Get-MgUser -All -Property Id, DisplayName, UserPrincipalName, AccountEnabled, Department, JobTitle, CreatedDateTime, AssignedLicenses `
                                -Filter $filter -ErrorAction SilentlyContinue |
                Select-Object @{Name = "ObjectId"; Expression = { $_.Id }},
                              DisplayName,
                              UserPrincipalName,
                              AccountEnabled,
                              Department,
                              JobTitle,
                              @{Name = "LicenseCount"; Expression = { $_.AssignedLicenses.Count }},
                              CreatedDateTime
        }
        elseif (Get-Command -Name Get-AzureADUser -ErrorAction SilentlyContinue) {
            # Fallback: AzureAD PowerShell
            $filter = if ($EnabledOnly) { "AccountEnabled eq true" } else { $null }
            $Users = Get-AzureADUser -All $true -Filter $filter -ErrorAction SilentlyContinue |
                Select-Object ObjectId, DisplayName, UserPrincipalName, AccountEnabled, Department, JobTitle
        }
        elseif (Get-Command -Name Get-MsolUser -ErrorAction SilentlyContinue) {
            # Fallback: MSOnline PowerShell
            $Users = Get-MsolUser -All -EnabledFilter $(if ($EnabledOnly) { "EnabledOnly" } else { "All" }) -ErrorAction SilentlyContinue |
                Select-Object ObjectId, DisplayName, UserPrincipalName, @{Name = "AccountEnabled"; Expression = { -not $_.BlockCredential }}, Department, Title
        }
        else {
            Write-Warning "No supported identity module (Microsoft.Graph, AzureAD, or MSOnline) is currently imported or connected."
            return
        }

        if ($Users) {
            Write-Host "Retrieved $(($Users | Measure-Object).Count) user records." -ForegroundColor Green
            if ($ExportPath) {
                $Users | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding utf8
                Write-Host "Export saved to: $ExportPath" -ForegroundColor Green
            }
            return $Users
        } else {
            Write-Warning "No users returned from directory query."
        }
    }
}

# Auto-execute if invoked as a standalone script
if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.Line -notmatch 'function') {
    Get-M365UserOverview
}
