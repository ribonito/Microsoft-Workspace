<#
.SYNOPSIS
    Configures tenant-wide Exchange Online organization settings and hydration state.

.DESCRIPTION
    Inspects and updates tenant-level configuration in Exchange Online. Performs tenant hydration
    via Enable-OrganizationCustomization (required before modifying default RBAC or address book policies),
    and manages organization-wide features such as Auto-Expanding Archiving.

.NOTES
    Requires ExchangeOnlineManagement module.
    Enable-OrganizationCustomization is a one-time operation per tenant and may take up to an hour to replicate.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - Organization Management.ps1
    Verifies tenant customization state and displays organization-wide configurations.

.LINK
    https://learn.microsoft.com/powershell/module/exchange/enable-organizationcustomization
    https://learn.microsoft.com/powershell/module/exchange/set-organizationconfig
    https://learn.microsoft.com/purview/auto-expanding-archiving
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$HydrateTenant,

    [Parameter(Mandatory = $false)]
    [switch]$EnableAutoExpandingArchive
)

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline

Write-Host "Checking Exchange Online Organization Configuration..." -ForegroundColor Cyan
$orgConfig = Get-OrganizationConfig

Write-Host "Tenant Name:               $($orgConfig.Name)" -ForegroundColor Yellow
Write-Host "Is Dehydrated:             $($orgConfig.IsDehydrated)" -ForegroundColor $(if ($orgConfig.IsDehydrated) { "Red" } else { "Green" })
Write-Host "Auto-Expanding Archive:    $($orgConfig.AutoExpandingArchiveEnabled)" -ForegroundColor Cyan

# 1. Tenant Hydration
if ($HydrateTenant -and $orgConfig.IsDehydrated) {
    Write-Host "`nHydrating tenant via Enable-OrganizationCustomization..." -ForegroundColor Cyan
    try {
        Enable-OrganizationCustomization
        Write-Host "Hydration command submitted successfully." -ForegroundColor Green
    } catch {
        Write-Warning "Failed or already in progress: $_"
    }
}

# 2. Auto-Expanding Archive
if ($EnableAutoExpandingArchive -and -not $orgConfig.AutoExpandingArchiveEnabled) {
    Write-Host "`nEnabling Auto-Expanding Archive tenant-wide..." -ForegroundColor Cyan
    Set-OrganizationConfig -AutoExpandingArchiveEnabled $true
    Write-Host "Auto-expanding archive enabled." -ForegroundColor Green
}