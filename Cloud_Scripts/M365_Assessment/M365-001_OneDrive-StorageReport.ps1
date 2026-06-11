<#
.SYNOPSIS
    M365-001 | M365 Assessment - OneDrive for Business Storage Consumption Report.

.DESCRIPTION
    Connects to SharePoint Online and generates a detailed report of all OneDrive
    for Business sites in the tenant, sorted by storage consumption (highest first).

    Output includes:
        - Owner display name and email
        - Site URL
        - Quota (GB) and Used (GB)
        - Percentage used

    Exports to CSV and displays an interactive grid view for quick analysis.

.PRODUCT
    SharePoint Online / OneDrive for Business

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    .\M365-001_OneDrive-StorageReport.ps1
    (You will be prompted for SPO Admin credentials)

.NOTES
    - Module: Microsoft.Online.SharePoint.PowerShell
    - Requires SharePoint Administrator role
    - Update the admin URL on line 34 to match your tenant
#>

#region ── Connection ─────────────────────────────────────────────────────────
Import-Module -Name Microsoft.Online.SharePoint.PowerShell
# Update this URL to match your tenant admin endpoint
Connect-SPOService -URL "https://<your-tenant>-admin.sharepoint.com/"
#endregion

#region ── Collect OneDrive Sites ─────────────────────────────────────────────
Write-Host "Discovering OneDrive for Business sites..." -ForegroundColor Cyan

[array]$ODFBSites = Get-SPOSite `
    -IncludePersonalSite $true `
    -Limit All `
    -Filter "Url -like '-my.sharepoint.com/personal/'" |
    Select-Object Owner, Title, URL, StorageQuota, StorageUsageCurrent |
    Sort-Object StorageUsageCurrent -Descending

if (-not $ODFBSites) {
    Write-Host "No OneDrive sites found." -ForegroundColor Yellow
    break
}
#endregion

#region ── Build Report ───────────────────────────────────────────────────────
$TotalUsedGB = [Math]::Round(
    ($ODFBSites.StorageUsageCurrent | Measure-Object -Sum).Sum / 1024, 2
)

$Report = [System.Collections.Generic.List[Object]]::new()

foreach ($Site in $ODFBSites) {
    $Report.Add([PSCustomObject]@{
        Owner       = $Site.Title
        Email       = $Site.Owner
        URL         = $Site.URL
        QuotaGB     = [Math]::Round($Site.StorageQuota / 1024, 2)
        UsedGB      = [Math]::Round($Site.StorageUsageCurrent / 1024, 4)
        PercentUsed = [Math]::Round(($Site.StorageUsageCurrent / $Site.StorageQuota * 100), 4)
    })
}
#endregion

#region ── Export & Display ───────────────────────────────────────────────────
$OutputPath = "C:\temp\OneDrive_StorageReport_$(Get-Date -Format 'yyyyMMdd').csv"
$Report | Export-CSV -NoTypeInformation -Path $OutputPath -Encoding UTF8

# Optional interactive grid view
$Report | Sort-Object UsedGB -Descending | Out-GridView -Title "OneDrive Storage Consumption"

Write-Host "Total OneDrive storage in use: $TotalUsedGB GB" -ForegroundColor Green
Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
#endregion
