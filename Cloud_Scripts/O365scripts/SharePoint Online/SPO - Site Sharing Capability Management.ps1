<#
.SYNOPSIS
    Manages external sharing capabilities on SharePoint Online and OneDrive site collections.

.DESCRIPTION
    Audits and configures external sharing permissions across SharePoint Online site collections
    and OneDrive for Business personal sites. Supports four standard sharing tiers:
    Disabled, ExistingExternalUserSharingOnly, ExternalUserSharingOnly, and ExternalUserAndGuestSharing (Anyone links).

.PARAMETER SiteUrl
    Optional absolute URL of the site to configure. If omitted, prompts with Out-GridView.

.PARAMETER SharingCapability
    The sharing capability to enforce: 'Disabled', 'ExistingExternalUserSharingOnly',
    'ExternalUserSharingOnly', or 'ExternalUserAndGuestSharing'.

.NOTES
    Requires Microsoft.Online.SharePoint.PowerShell module.
    Tenant-level sharing settings must permit equal or greater sharing than the individual site collection.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\SPO - Site Sharing Capability Management.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/ExtCollab" -SharingCapability "ExternalUserSharingOnly"
    Sets the specified site to allow authenticated guest and external user sharing.

.LINK
    https://learn.microsoft.com/sharepoint/turn-external-sharing-on-or-off
    https://learn.microsoft.com/powershell/module/sharepoint-online/set-sposite
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Disabled", "ExistingExternalUserSharingOnly", "ExternalUserSharingOnly", "ExternalUserAndGuestSharing")]
    [string]$SharingCapability = "ExternalUserSharingOnly"
)

# Connect to SharePoint Online Admin Center
Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction SilentlyContinue

if (-not [string]::IsNullOrWhiteSpace($SiteUrl)) {
    Write-Host "Configuring SharingCapability on '$SiteUrl' to '$SharingCapability'..." -ForegroundColor Cyan
    Set-SPOSite -Identity $SiteUrl -SharingCapability $SharingCapability
    Get-SPOSite -Identity $SiteUrl | Select-Object Url, SharingCapability | Format-List
}
else {
    Write-Host "Select site(s) to adjust external sharing settings:" -ForegroundColor Cyan
    $selectedSites = Get-SPOSite -Limit All |
        Select-Object Url, SharingCapability, StorageUsageCurrent |
        Out-GridView -Title "Select site(s) to update external sharing" -PassThru

    if ($selectedSites) {
        foreach ($s in $selectedSites) {
            Write-Host "Updating $($s.Url) to $SharingCapability..." -ForegroundColor Yellow
            Set-SPOSite -Identity $s.Url -SharingCapability $SharingCapability
        }
        Write-Host "Sharing capability update completed." -ForegroundColor Green
    } else {
        Write-Warning "No sites selected."
    }
}
