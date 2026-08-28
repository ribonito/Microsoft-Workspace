<#
.SYNOPSIS
    M365-017 | Export Unified Groups and Associated SharePoint Site Report.

.DESCRIPTION
    PowerShell script that reads all Unified Groups (Microsoft 365 Groups) in a tenant, 
    retrieves their metadata and associated SharePoint Online site storage quotas and usage, 
    and exports a combined inventory report to a CSV file.

.PRODUCT
    Microsoft 365 / SharePoint Online

.ORIGINAL_AUTHOR
    Martina Grom - atwork.at

.MAINTAINER
    Josep Canas - M365 Solutions Architect (M365-017 classification)

.VERSION
    1.0

.NOTES
    Name: M365-017_Export-Unified-Groups-Report.ps1
    Requires: Connect-ExchangeOnline and Connect-SPOService established beforehand.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
# Specifies the location where the result files shall be saved
$ResultFile = '.\get-unifiedgroups.csv'
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Get all Office 365 groups of the tenant: $groups = Get-UnifiedGroup
# But we need only specific properties including the lookup of the manager done by the Cmdlet itself.
$groups = Get-UnifiedGroup -ResultSize Unlimited | Select-Object Name, Alias, PrimarySmtpAddress, AccessType, SharePointSiteUrl, SharePointDocumentsUrl, @{n = 'Manager'; e = { $(Get-Recipient -Identity $($_.ManagedBy[0])).PrimarySmtpAddress } }

# Use custom class structure for combining the result
class LineProperties
{
    [string]$Number
    [string]$Name
    [string]$PrimarySmtpAddress
    [string]$AccessType
    [string]$Manager
    [string]$SharePointSiteUrl
    [string]$SharePointDocumentsUrl
    [string]$StorageQuota
    [string]$StorageUsageCurrent
    [string]$WebsCount
    [string]$LastContentModifiedDate
}

# Add each group to the result
Write-Output "Running..."
$all = @()
$i = 0
foreach ($group in $groups) { 
    $i++
    Write-Output "$($i). $($group.Alias)"

    # properties we always have...
    $c = New-Object LineProperties
    $c.Number = $i
    $c.Name = $group.Alias
    $c.PrimarySmtpAddress = $group.PrimarySmtpAddress
    $c.AccessType = $group.AccessType
    $c.Manager = $group.Manager
    $c.SharePointSiteUrl = 'not provisioned'

    # add and overwrite following data only, if a SharePoint Site is provisioned for this group.
    if ($group.SharePointSiteUrl -ne $null) {
        $SPOSite = (Get-SPOSite -Identity $group.SharePointSiteUrl)

        $c.SharePointSiteUrl = $group.SharePointSiteUrl
        $c.SharePointDocumentsUrl = $group.SharePointDocumentsUrl
        $c.StorageQuota = $SPOSite.StorageQuota
        $c.StorageUsageCurrent = $SPOSite.StorageUsageCurrent
        $c.LastContentModifiedDate = $SPOSite.LastContentModifiedDate
        $c.WebsCount = $SPOSite.WebsCount
    }

    $all += $c
}

# Delete the $ResultFile if existing and output
if (Test-Path $ResultFile) {
    Remove-Item -Path $ResultFile -Force
}
Write-Output $all | Export-Csv -Path $ResultFile -NoClobber -NoTypeInformation -Encoding UTF8 -Force -Delimiter ','

Write-Output "Done. $($groups.Count) groups. Details saved to $($ResultFile)"
#endregion
