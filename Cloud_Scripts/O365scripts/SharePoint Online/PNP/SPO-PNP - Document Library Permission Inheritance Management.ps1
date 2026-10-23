<#
.SYNOPSIS
    Manages permission inheritance on SharePoint Online document libraries using PnP PowerShell.

.DESCRIPTION
    Audits, breaks, or restores role inheritance on SharePoint Online document libraries and lists.
    When breaking inheritance, optionally retains existing permissions or clears unique assignments.
    Provides complete lifecycle management for document library security.

.PARAMETER SiteUrl
    The URL of the target SharePoint Online site collection.

.PARAMETER ListTitle
    The title of the Document Library or List (e.g. 'Shared Documents' or 'Documents').

.PARAMETER Action
    Action to perform: 'BreakInheritance', 'RestoreInheritance', or 'Audit'. Defaults to 'Audit'.

.PARAMETER CopyRoleAssignments
    When breaking inheritance, whether to keep current permissions (true) or clear them (false). Defaults to true.

.NOTES
    Requires PnP.PowerShell module.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\SPO-PNP - Document Library Permission Inheritance Management.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/Legal" -ListTitle "Confidential" -Action "BreakInheritance"
    Breaks permission inheritance on the Confidential document library while copying current role assignments.

.LINK
    https://pnp.github.io/powershell/cmdlets/Set-PnPList.html
    https://learn.microsoft.com/sharepoint/modern-experience-custom-permissions
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$SiteUrl = "https://tenant.sharepoint.com/sites/Sitename",

    [Parameter(Mandatory = $false, Position = 1)]
    [string]$ListTitle = "Documents",

    [Parameter(Mandatory = $false)]
    [ValidateSet("BreakInheritance", "RestoreInheritance", "Audit")]
    [string]$Action = "Audit",

    [Parameter(Mandatory = $false)]
    [bool]$CopyRoleAssignments = $true
)

# Connect via PnP PowerShell
Import-Module PnP.PowerShell -ErrorAction SilentlyContinue

if ($SiteUrl -notlike "*Sitename*") {
    Connect-PnPOnline -Url $SiteUrl -Interactive
} else {
    Write-Warning "Specify a valid -SiteUrl parameter to execute list permission management."
    return
}

$List = Get-PnPList -Identity $ListTitle -ErrorAction Stop

Write-Host "`nTarget List: $($List.Title)" -ForegroundColor Cyan
Write-Host "Has Unique Role Assignments: $($List.HasUniqueRoleAssignments)" -ForegroundColor $(if ($List.HasUniqueRoleAssignments) { "Yellow" } else { "Green" })

switch ($Action) {
    "BreakInheritance" {
        if (-not $List.HasUniqueRoleAssignments) {
            Write-Host "Breaking permission inheritance on '$ListTitle' (CopyRoleAssignments: $CopyRoleAssignments)..." -ForegroundColor Yellow
            Set-PnPList -Identity $ListTitle -BreakRoleInheritance -CopyRoleAssignments:$CopyRoleAssignments
            Write-Host "Inheritance broken successfully." -ForegroundColor Green
        } else {
            Write-Host "List '$ListTitle' already has unique permissions." -ForegroundColor Gray
        }
    }
    "RestoreInheritance" {
        if ($List.HasUniqueRoleAssignments) {
            Write-Host "Restoring permission inheritance on '$ListTitle' to inherit from parent site..." -ForegroundColor Yellow
            Set-PnPList -Identity $ListTitle -ResetRoleInheritance
            Write-Host "Inheritance restored successfully." -ForegroundColor Green
        } else {
            Write-Host "List '$ListTitle' is already inheriting permissions." -ForegroundColor Gray
        }
    }
    "Audit" {
        Write-Host "Auditing role assignments for '$ListTitle'..." -ForegroundColor Cyan
        Get-PnPGroup | Select-Object Title, Id | Format-Table -AutoSize
    }
}
