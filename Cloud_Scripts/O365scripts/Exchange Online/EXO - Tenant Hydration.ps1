<#
.SYNOPSIS
    Performs tenant hydration (Enable-OrganizationCustomization) in Exchange Online.

.DESCRIPTION
    Audits the current hydration state of the Exchange Online organization and triggers
    Enable-OrganizationCustomization if the tenant is currently dehydrated. Dehydrated tenants
    share common configuration objects and cannot modify certain RBAC or policy settings until
    hydrated.

.NOTES
    Requires ExchangeOnlineManagement module and Global Administrator or Exchange Administrator privileges.
    Hydration is an asynchronous operation and can take up to 60 minutes to complete.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - Tenant Hydration.ps1
    Verifies tenant hydration status and initiates hydration if required.

.LINK
    https://learn.microsoft.com/powershell/module/exchange/enable-organizationcustomization
    https://learn.microsoft.com/powershell/module/exchange/get-organizationconfig
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$AdminUpn
)

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
if (-not [string]::IsNullOrWhiteSpace($AdminUpn)) {
    Connect-ExchangeOnline -UserPrincipalName $AdminUpn
} else {
    Connect-ExchangeOnline
}

Write-Host "Verifying Exchange Online tenant hydration state..." -ForegroundColor Cyan
$org = Get-OrganizationConfig

Write-Host "Tenant Name:   $($org.Name)" -ForegroundColor Yellow
Write-Host "IsDehydrated:  $($org.IsDehydrated)" -ForegroundColor $(if ($org.IsDehydrated) { "Red" } else { "Green" })

if ($org.IsDehydrated) {
    Write-Host "Tenant is dehydrated. Initiating Enable-OrganizationCustomization..." -ForegroundColor Yellow
    try {
        Enable-OrganizationCustomization -Confirm:$false
        Write-Host "Organization customization initiated. Please allow up to an hour for full replication." -ForegroundColor Green
    } catch {
        Write-Warning "Failed to enable organization customization: $_"
    }
} else {
    Write-Host "Tenant is already hydrated. Custom RBAC and organizational policies can be applied." -ForegroundColor Green
}
