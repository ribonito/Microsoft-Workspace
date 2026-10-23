<#
.SYNOPSIS
    Manages storage quotas and warning thresholds on SharePoint Online and OneDrive site collections.

.DESCRIPTION
    Configures StorageQuota (maximum allowed storage in megabytes) and StorageQuotaWarningLevel
    on individual SharePoint Online site collections or OneDrive for Business personal sites.
    Allows adjusting user OneDrive capacity from standard 1TB to 5TB with appropriate licensing.

.PARAMETER SiteUrl
    The absolute URL of the SharePoint Online or OneDrive for Business personal site collection.

.PARAMETER QuotaInMB
    Total storage quota in megabytes (e.g., 5242880 for 5TB, 1048576 for 1TB).

.PARAMETER WarningLevelInMB
    Storage warning notification threshold in megabytes.

.NOTES
    Requires Microsoft.Online.SharePoint.PowerShell module.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\SPO - Site Quota.ps1 -SiteUrl "https://contoso-my.sharepoint.com/personal/user_contoso_com" -QuotaInMB 5242880
    Sets the specified user's OneDrive for Business storage quota to 5TB.

.LINK
    https://learn.microsoft.com/sharepoint/manage-site-collection-storage-limits
    https://learn.microsoft.com/powershell/module/sharepoint-online/set-sposite
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$SiteUrl = "https://tenant-my.sharepoint.com/personal/user_domain_com",

    [Parameter(Mandatory = $false)]
    [int64]$QuotaInMB = 5242880, # 5TB

    [Parameter(Mandatory = $false)]
    [int64]$WarningLevelInMB = 4980736 # ~4.75TB
)

# Connect to SharePoint Online Admin Center
Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction SilentlyContinue

if (-not [string]::IsNullOrWhiteSpace($SiteUrl) -and $SiteUrl -notlike "*user_domain_com*") {
    Write-Host "Updating storage quota on site '$SiteUrl'..." -ForegroundColor Cyan
    Set-SPOSite -Identity $SiteUrl -StorageQuota $QuotaInMB -StorageQuotaWarningLevel $WarningLevelInMB
    
    Write-Host "Updated Quota Configuration:" -ForegroundColor Green
    Get-SPOSite -Identity $SiteUrl | Select-Object Url, StorageQuota, StorageQuotaWarningLevel, StorageUsageCurrent | Format-List
}
else {
    Write-Host "Select site to adjust storage quota:" -ForegroundColor Cyan
    $site = Get-SPOSite -Limit All | Out-GridView -Title "Select site to adjust quota" -OutputMode Single
    if ($site) {
        Set-SPOSite -Identity $site.Url -StorageQuota $QuotaInMB -StorageQuotaWarningLevel $WarningLevelInMB
        Write-Host "Storage quota updated on $($site.Url)." -ForegroundColor Green
    }
}
