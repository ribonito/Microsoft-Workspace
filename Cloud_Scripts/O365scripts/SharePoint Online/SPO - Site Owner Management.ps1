<#
.SYNOPSIS
    Assigns Site Collection Administrators (Owners) across SharePoint Online site collections.

.DESCRIPTION
    Provides automated procedures to grant Site Collection Administrator privileges on target
    SharePoint Online site collections to specified administrative users or security group members.
    Supports interactive multi-site selection via Out-GridView.

.PARAMETER SiteUrl
    The absolute URL of the SharePoint Online site collection.

.PARAMETER AdminUser
    The login name or UserPrincipalName of the administrator to grant Site Collection Admin rights.

.NOTES
    Requires Microsoft.Online.SharePoint.PowerShell module.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\SPO - Site Owner Management.ps1 -SiteUrl "https://contoso.sharepoint.com/sites/Finance" -AdminUser "admin@contoso.com"
    Adds admin@contoso.com as a primary site collection administrator on the Finance site.

.LINK
    https://learn.microsoft.com/powershell/module/sharepoint-online/set-spouser
    https://learn.microsoft.com/sharepoint/manage-site-collection-administrators
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SiteUrl,

    [Parameter(Mandatory = $false)]
    [string]$AdminUser = "admin@domain.com"
)

# Connect to SharePoint Online Admin Center
Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction SilentlyContinue

if (-not [string]::IsNullOrWhiteSpace($SiteUrl) -and -not [string]::IsNullOrWhiteSpace($AdminUser)) {
    Write-Host "Assigning Site Collection Administrator on '$SiteUrl' to '$AdminUser'..." -ForegroundColor Cyan
    try {
        Set-SPOUser -Site $SiteUrl -LoginName $AdminUser -IsSiteCollectionAdmin $true -ErrorAction Stop
        Write-Host "Site Collection Administrator privileges successfully granted." -ForegroundColor Green
    } catch {
        Write-Error "Failed to grant Site Collection Admin on $($SiteUrl): $_"
    }
}
else {
    Write-Host "Interactively select site collection(s) to assign administrator '$AdminUser':" -ForegroundColor Cyan
    $ListSites = Get-SPOSite -Limit All | Out-GridView -Title "Select Site Collection(s)" -PassThru
    if ($ListSites) {
        foreach ($s in $ListSites) {
            Write-Host "Adding $AdminUser to $($s.Url)..." -ForegroundColor Yellow
            Set-SPOUser -Site $s.Url -LoginName $AdminUser -IsSiteCollectionAdmin $true -ErrorAction SilentlyContinue
        }
        Write-Host "Assignment complete." -ForegroundColor Green
    } else {
        Write-Warning "No sites selected."
    }
}
