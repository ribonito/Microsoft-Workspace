<#
.SYNOPSIS
    SPO-001 | SharePoint Online - Pre-Migration Assessment.

.DESCRIPTION
    Generates a comprehensive pre-migration inventory of sites, libraries, permissions, and hub memberships.
    Useful for M365 solution architects in planning migrations (On-Premises to SPO or Tenant-to-Tenant).

.PRODUCT
    SharePoint Online / PnP PowerShell

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - Module: PnP.PowerShell (>= 2.x)
    - Authentication: App Registration (Sites.Read.All and User.Read.All scopes)

.PARAMETER TenantAdminUrl
    URL of the SharePoint Admin Center (e.g., https://contoso-admin.sharepoint.com).

.PARAMETER OutputPath
    Local path where the CSV reports will be saved.

.PARAMETER ClientId
    Client ID (AppID) of the Entra ID App Registration.

.PARAMETER Thumbprint
    Thumbprint of the certificate used for app-only authentication.

.PARAMETER TenantId
    Tenant ID (Directory ID GUID) of the Entra ID tenant.

.EXAMPLE
    .\SPO-001_PreMigration-Assessment.ps1 `
        -TenantAdminUrl "https://contoso-admin.sharepoint.com" `
        -ClientId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
        -Thumbprint "AABBCC..." `
        -TenantId "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" `
        -OutputPath "C:\MigrationReports"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TenantAdminUrl,

    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    [Parameter(Mandatory = $true)]
    [string]$Thumbprint,

    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "$env:USERPROFILE\Desktop\SPO_Assessment_$(Get-Date -Format 'yyyyMMdd_HHmm')"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#region ── Helpers ────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [ValidateSet('INFO','WARN','ERROR')]$Level = 'INFO')
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = @{ INFO = 'Cyan'; WARN = 'Yellow'; ERROR = 'Red' }[$Level]
    Write-Host "[$timestamp][$Level] $Message" -ForegroundColor $color
    Add-Content -Path "$OutputPath\assessment.log" -Value "[$timestamp][$Level] $Message"
}

function Ensure-Output {
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Log "Output directory created: $OutputPath"
    }
}
#endregion

#region ── Connection ─────────────────────────────────────────────────────────
Ensure-Output

Write-Log "Connecting to SharePoint Admin Center: $TenantAdminUrl"
Connect-PnPOnline -Url $TenantAdminUrl `
    -ClientId $ClientId `
    -Thumbprint $Thumbprint `
    -Tenant $TenantId
Write-Log "Connection established."
#endregion

#region ── 1. Site Inventory ──────────────────────────────────────────────────
Write-Log "Retrieving tenant sites list..."

$allSites = Get-PnPTenantSite -IncludeOneDriveSites:$false -Detailed |
    Select-Object Url, Title, Template, StorageUsageCurrent, StorageMaximumLevel,
                  SharingCapability, LockState, LastContentModifiedDate,
                  Owner, SiteDefinedSharingCapability, GroupId, HubSiteId,
                  ConditionalAccessPolicy, SensitivityLabel, RelatedGroupId

$allSites | Export-Csv "$OutputPath\01_SiteInventory.csv" -NoTypeInformation -Encoding UTF8
Write-Log "Sites exported: $($allSites.Count)"
#endregion

#region ── 2. Large Sites (> 25 GB) ───────────────────────────────────────────
$largeSites = $allSites | Where-Object { $_.StorageUsageCurrent -gt 25600 }
$largeSites | Export-Csv "$OutputPath\02_LargeSites_Over25GB.csv" -NoTypeInformation -Encoding UTF8
Write-Log "Large sites (> 25 GB): $($largeSites.Count)"
#endregion

#region ── 3. Detailed Site Inventory ─────────────────────────────────────────
Write-Log "Starting detailed site-by-site analysis..."

$libraryReport   = [System.Collections.Generic.List[PSObject]]::new()
$permissionReport= [System.Collections.Generic.List[PSObject]]::new()
$hubReport       = [System.Collections.Generic.List[PSObject]]::new()

foreach ($site in $allSites) {
    Write-Log "Processing site: $($site.Url)"
    try {
        Connect-PnPOnline -Url $site.Url `
            -ClientId $ClientId `
            -Thumbprint $Thumbprint `
            -Tenant $TenantId

        # ── 3a. Libraries and Lists ───────────────────────────────────────
        $lists = Get-PnPList | Where-Object { -not $_.Hidden }
        foreach ($list in $lists) {
            $libraryReport.Add([PSCustomObject]@{
                SiteUrl         = $site.Url
                ListTitle       = $list.Title
                BaseTemplate    = $list.BaseTemplate
                ItemCount       = $list.ItemCount
                LastModified    = $list.LastItemModifiedDate
                EnableVersioning= $list.EnableVersioning
                MajorVersions   = $list.MajorVersionLimit
                MinorVersions   = $list.MajorWithMinorVersionsLimit
                IRMEnabled      = $list.IrmEnabled
                ContentTypesEnabled = $list.ContentTypesEnabled
            })
        }

        # ── 3b. Unique site permissions ───────────────────────────────────
        $web = Get-PnPWeb -Includes HasUniqueRoleAssignments, RoleAssignments, RoleAssignments.Member, RoleAssignments.RoleDefinitionBindings
        if ($web.HasUniqueRoleAssignments) {
            foreach ($ra in $web.RoleAssignments) {
                $permissionReport.Add([PSCustomObject]@{
                    SiteUrl     = $site.Url
                    Principal   = $ra.Member.LoginName
                    PrincipalType = $ra.Member.PrincipalType
                    Roles       = ($ra.RoleDefinitionBindings | Select-Object -ExpandProperty Name) -join '; '
                    IsInherited = $false
                })
            }
        }

        # ── 3c. Hub site membership ───────────────────────────────────────
        if ($site.HubSiteId -ne [Guid]::Empty) {
            $hubReport.Add([PSCustomObject]@{
                SiteUrl   = $site.Url
                SiteTitle = $site.Title
                HubSiteId = $site.HubSiteId
            })
        }

    } catch {
        Write-Log "Error on site $($site.Url): $_" -Level WARN
    }
}

$libraryReport    | Export-Csv "$OutputPath\03_LibraryInventory.csv"    -NoTypeInformation -Encoding UTF8
$permissionReport | Export-Csv "$OutputPath\04_UniquePermissions.csv"   -NoTypeInformation -Encoding UTF8
$hubReport        | Export-Csv "$OutputPath\05_HubSiteMembers.csv"      -NoTypeInformation -Encoding UTF8

Write-Log "Libraries analyzed: $($libraryReport.Count)"
Write-Log "Unique permission assignments: $($permissionReport.Count)"
#endregion

#region ── 4. Executive Summary ───────────────────────────────────────────────
$summary = [PSCustomObject]@{
    AnalysisDate          = Get-Date -Format 'yyyy-MM-dd HH:mm'
    TotalSites            = $allSites.Count
    LargeSites            = $largeSites.Count
    TotalLibraries        = $libraryReport.Count
    TotalUniquePermissions = $permissionReport.Count
    SitesInHub            = $hubReport.Count
    TotalStorageGB        = [math]::Round(($allSites | Measure-Object -Property StorageUsageCurrent -Sum).Sum / 1024, 2)
}

$summary | ConvertTo-Json | Out-File "$OutputPath\00_ExecutiveSummary.json" -Encoding UTF8
Write-Log "=== ASSESSMENT COMPLETED ===" 
Write-Log "Results saved to: $OutputPath"

Disconnect-PnPOnline
#endregion
