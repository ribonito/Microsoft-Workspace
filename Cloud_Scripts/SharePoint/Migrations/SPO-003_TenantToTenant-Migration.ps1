<#
.SYNOPSIS
    SPO-003 | SharePoint Online - Tenant-to-Tenant (T2T) Site Migration.

.DESCRIPTION
    Orchestrates the complete migration of a site between two Microsoft 365 tenants.
    Follows Microsoft's recommended flow for T2T migrations:
        1. Export PnP template from the source tenant.
        2. Export document library files locally.
        3. Provision destination site and apply PnP template.
        4. Replicate security group membership (mapping source users to destination via CSV).
        5. Generate a post-migration status report.

.PRODUCT
    SharePoint Online / PnP PowerShell

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - Module: PnP.PowerShell (>= 2.x) on BOTH tenants
    - Authentication: App registrations with certificate authentication in both source and destination tenants
    - User mapping CSV file schema: SourceUPN, DestinationUPN

.PARAMETER SourceTenantAdminUrl
    URL of the source tenant SharePoint Admin Center.

.PARAMETER DestTenantAdminUrl
    URL of the destination tenant SharePoint Admin Center.

.PARAMETER SourceSiteUrl
    URL of the site to migrate in the source tenant.

.PARAMETER DestSiteUrl
    URL of the destination site in the target tenant.

.PARAMETER SourceClientId
    Client ID (AppID) of the source tenant App Registration.

.PARAMETER DestClientId
    Client ID (AppID) of the destination tenant App Registration.

.PARAMETER SourceThumbprint
    Thumbprint of the certificate used in the source tenant App Registration.

.PARAMETER DestThumbprint
    Thumbprint of the certificate used in the destination tenant App Registration.

.PARAMETER SourceTenantId
    Tenant ID (Directory ID GUID) of the source tenant.

.PARAMETER DestTenantId
    Tenant ID (Directory ID GUID) of the destination tenant.

.PARAMETER UserMappingCsv
    CSV mapping file path containing 'SourceUPN' and 'DestinationUPN' columns.

.PARAMETER WorkingFolder
    Local temporary directory where templates, files, and logs are temporarily saved.

.EXAMPLE
    .\SPO-003_TenantToTenant-Migration.ps1 `
        -SourceTenantAdminUrl "https://sourcecontoso-admin.sharepoint.com" `
        -DestTenantAdminUrl   "https://destcontoso-admin.sharepoint.com" `
        -SourceSiteUrl "https://sourcecontoso.sharepoint.com/sites/HR" `
        -DestSiteUrl   "https://destcontoso.sharepoint.com/sites/HR" `
        -SourceClientId "src-app-id" -SourceThumbprint "SRC..." -SourceTenantId "src-tid" `
        -DestClientId   "dst-app-id" -DestThumbprint   "DST..." -DestTenantId   "dst-tid" `
        -UserMappingCsv "C:\T2T\UserMapping.csv"
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    # Source Tenant
    [Parameter(Mandatory=$true)][string]$SourceTenantAdminUrl,
    [Parameter(Mandatory=$true)][string]$SourceSiteUrl,
    [Parameter(Mandatory=$true)][string]$SourceClientId,
    [Parameter(Mandatory=$true)][string]$SourceThumbprint,
    [Parameter(Mandatory=$true)][string]$SourceTenantId,

    # Destination Tenant
    [Parameter(Mandatory=$true)][string]$DestTenantAdminUrl,
    [Parameter(Mandatory=$true)][string]$DestSiteUrl,
    [Parameter(Mandatory=$true)][string]$DestClientId,
    [Parameter(Mandatory=$true)][string]$DestThumbprint,
    [Parameter(Mandatory=$true)][string]$DestTenantId,

    # Extras
    [Parameter(Mandatory=$false)][string]$UserMappingCsv,
    [Parameter(Mandatory=$false)][string]$WorkingFolder = "$env:TEMP\T2T_Migration_$(Get-Date -Format 'yyyyMMdd_HHmm')"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

if (-not (Test-Path $WorkingFolder)) { New-Item -ItemType Directory -Path $WorkingFolder -Force | Out-Null }
$LogFile     = "$WorkingFolder\T2T_Migration.log"
$TemplatePath= "$WorkingFolder\SiteTemplate.xml"
$ReportPath  = "$WorkingFolder\MigrationReport.csv"

#region ── Helpers ────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [ValidateSet('INFO','WARN','ERROR','SUCCESS','PHASE')]$Level = 'INFO')
    $ts = Get-Date -Format 'HH:mm:ss'
    $map = @{ INFO='Cyan'; WARN='Yellow'; ERROR='Red'; SUCCESS='Green'; PHASE='Magenta' }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $map[$Level]
    Add-Content -Path $LogFile -Value "[$ts][$Level] $Message"
}

function ConnectSource { Connect-PnPOnline -Url $SourceSiteUrl -ClientId $SourceClientId -Thumbprint $SourceThumbprint -Tenant $SourceTenantId }
function ConnectDest   { Connect-PnPOnline -Url $DestSiteUrl   -ClientId $DestClientId   -Thumbprint $DestThumbprint   -Tenant $DestTenantId   }

function Map-User {
    param([string]$SourceUpn)
    if (-not $userMap) { return $SourceUpn }
    $mapped = $userMap | Where-Object { $_.SourceUPN -eq $SourceUpn }
    return ($mapped ? $mapped.DestinationUPN : $SourceUpn)
}

# Load user mappings if provided
$userMap = $null
if ($UserMappingCsv -and (Test-Path $UserMappingCsv)) {
    $userMap = Import-Csv $UserMappingCsv
    Write-Log "User mapping file loaded: $($userMap.Count) entries."
}

$migrationResults = [System.Collections.Generic.List[PSObject]]::new()
#endregion

#region ── Phase 1: Source Site Analysis ──────────────────────────────────────
Write-Log "=== PHASE 1: Analyzing SOURCE site ===" -Level PHASE
ConnectSource

$sourceWeb     = Get-PnPWeb -Includes Title, Description, Language, RegionalSettings
$sourceLists   = Get-PnPList | Where-Object { -not $_.Hidden }
$sourcePages   = Get-PnPListItem -List "Site Pages" -PageSize 200 -ErrorAction SilentlyContinue

Write-Log "Source site: $($sourceWeb.Title)"
Write-Log "Lists/Libraries: $($sourceLists.Count)"
Write-Log "Pages: $($sourcePages.Count)"
#endregion

#region ── Phase 2: Export PnP Template ───────────────────────────────────────
Write-Log "=== PHASE 2: Exporting PnP Template ===" -Level PHASE

$handlers = "Lists,Fields,ContentTypes,CustomActions,Features,Files,Navigation,Pages,PageContents,Publishing,RegionalSettings,SearchSettings,SitePolicy,SupportedUILanguages,WebSettings,Workflows"

try {
    Get-PnPSiteTemplate -Out $TemplatePath -Handlers $handlers `
        -IncludeAllClientSidePages `
        -PersistBrandingFiles `
        -PersistPublishingFiles `
        -ErrorAction Stop
    Write-Log "Template exported to: $TemplatePath" -Level SUCCESS
} catch {
    Write-Log "Error exporting template: $_" -Level ERROR
    exit 1
}
#endregion

#region ── Phase 3: Export Files/Content ──────────────────────────────────────
Write-Log "=== PHASE 3: Downloading library content ===" -Level PHASE

foreach ($list in $sourceLists | Where-Object { $_.BaseTemplate -eq 101 }) {
    $localLibPath = "$WorkingFolder\Content\$($list.Title)"
    if (-not (Test-Path $localLibPath)) { New-Item -ItemType Directory -Path $localLibPath -Force | Out-Null }

    Write-Log "Exporting library: $($list.Title) ($($list.ItemCount) items)"
    $items = Get-PnPListItem -List $list.Title -PageSize 500 -Fields "FileRef","FileLeafRef","Modified","Author"

    foreach ($item in $items) {
        $fileRef = $item["FileRef"]
        if (-not $fileRef) { continue }
        try {
            Get-PnPFile -Url $fileRef -Path $localLibPath -FileName $item["FileLeafRef"] -AsFile -Force
        } catch {
            Write-Log "  Download failed: $fileRef - $_" -Level WARN
            $migrationResults.Add([PSCustomObject]@{
                Status    = "WARN"
                Type      = "File"
                Source    = $fileRef
                Detail    = $_.ToString()
            })
        }
    }
}
Write-Log "Download completed. Files saved to: $WorkingFolder\Content" -Level SUCCESS
#endregion

#region ── Phase 4: Create Destination Site ───────────────────────────────────
Write-Log "=== PHASE 4: Preparing DESTINATION site ===" -Level PHASE

Connect-PnPOnline -Url $DestTenantAdminUrl -ClientId $DestClientId -Thumbprint $DestThumbprint -Tenant $DestTenantId

$destAlias = ($DestSiteUrl -split "/sites/")[1]
$existingDestSite = Get-PnPTenantSite -Url $DestSiteUrl -ErrorAction SilentlyContinue

if (-not $existingDestSite) {
    Write-Log "Creating destination site: $DestSiteUrl"
    if ($PSCmdlet.ShouldProcess($DestSiteUrl, "Create destination site")) {
        New-PnPSite -Type TeamSite `
            -Title $sourceWeb.Title `
            -Alias $destAlias `
            -Description $sourceWeb.Description `
            -Lcid $sourceWeb.Language `
            -ErrorAction Stop | Out-Null
        Write-Log "Destination site created successfully." -Level SUCCESS
    }
} else {
    Write-Log "Destination site already exists: $DestSiteUrl" -Level WARN
}
#endregion

#region ── Phase 5: Apply PnP Template to Destination ─────────────────────────
Write-Log "=== PHASE 5: Applying PnP template to destination ===" -Level PHASE
ConnectDest

if ($PSCmdlet.ShouldProcess($DestSiteUrl, "Apply PnP template")) {
    try {
        Invoke-PnPSiteTemplate -Path $TemplatePath `
            -ClearNavigation `
            -OverwriteSystemPropertyBagValues
        Write-Log "PnP template successfully applied." -Level SUCCESS
    } catch {
        Write-Log "Error applying template: $_" -Level ERROR
    }
}
#endregion

#region ── Phase 6: Upload Content to Destination ─────────────────────────────
Write-Log "=== PHASE 6: Uploading files to destination ===" -Level PHASE

$contentRoot = "$WorkingFolder\Content"
if (Test-Path $contentRoot) {
    $localLibs = Get-ChildItem -Path $contentRoot -Directory
    foreach ($lib in $localLibs) {
        $files = Get-ChildItem -Path $lib.FullName -File -Recurse
        Write-Log "Uploading $($files.Count) file(s) to library '$($lib.Name)'"
        foreach ($file in $files) {
            try {
                $relativePath = $file.FullName.Substring($lib.FullName.Length + 1)
                $destFolder   = "$($lib.Name)/" + ($relativePath | Split-Path -Parent)
                Add-PnPFile -Path $file.FullName -Folder $destFolder -ErrorAction Stop | Out-Null
                $migrationResults.Add([PSCustomObject]@{
                    Status = "SUCCESS"; Type = "File"; Source = $file.FullName; Detail = "OK"
                })
            } catch {
                Write-Log "  Error uploading '$($file.Name)': $_" -Level WARN
                $migrationResults.Add([PSCustomObject]@{
                    Status = "ERROR"; Type = "File"; Source = $file.FullName; Detail = $_.ToString()
                })
            }
        }
    }
}
#endregion

#region ── Phase 7: Replicate Permissions ─────────────────────────────────────
Write-Log "=== PHASE 7: Replicating permissions with user mapping ===" -Level PHASE

ConnectSource
$sourceGroups = Get-PnPGroup
ConnectDest

foreach ($group in $sourceGroups) {
    $memberReport = @()
    ConnectSource
    $members = Get-PnPGroupMember -Identity $group.Title -ErrorAction SilentlyContinue
    ConnectDest

    $existing = Get-PnPGroup -Identity $group.Title -ErrorAction SilentlyContinue
    if (-not $existing) {
        New-PnPGroup -Title $group.Title -Description $group.Description | Out-Null
    }

    foreach ($member in $members) {
        $destUpn = Map-User -SourceUpn $member.LoginName
        try {
            Add-PnPGroupMember -LoginName $destUpn -Identity $group.Title -ErrorAction Stop
            Write-Log "  Added $destUpn to group '$($group.Title)'" -Level SUCCESS
        } catch {
            Write-Log "  Failed to add $destUpn to group '$($group.Title)': $_" -Level WARN
        }
    }
}
#endregion

#region ── Phase 8: Post-Migration Report ─────────────────────────────────────
Write-Log "=== PHASE 8: Generating migration report ===" -Level PHASE

$migrationResults | Export-Csv $ReportPath -NoTypeInformation -Encoding UTF8

$successCount = ($migrationResults | Where-Object { $_.Status -eq 'SUCCESS' }).Count
$errorCount   = ($migrationResults | Where-Object { $_.Status -eq 'ERROR'   }).Count
$warnCount    = ($migrationResults | Where-Object { $_.Status -eq 'WARN'    }).Count

Write-Log "======================================"   -Level SUCCESS
Write-Log "T2T MIGRATION PROCESS COMPLETED"           -Level SUCCESS
Write-Log "  ✅ Success : $successCount"             -Level SUCCESS
Write-Log "  ⚠️  Warnings: $warnCount"               -Level WARN
Write-Log "  ❌ Errors  : $errorCount"               -Level ERROR
Write-Log "  Report file: $ReportPath"               -Level SUCCESS
Write-Log "======================================"   -Level SUCCESS

Disconnect-PnPOnline
#endregion
