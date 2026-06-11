<#
.SYNOPSIS
    SPO-002 | SharePoint Online - Site Migration Classic to Modern.

.DESCRIPTION
    Performs a complete migration of a SharePoint classic or on-premises site to a modern structure
    using PnP PowerShell. It exports and applies site templates, configures modern features,
    migrates library contents (files with metadata), and replicates groups.

.PRODUCT
    SharePoint Online / PnP PowerShell

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - Module: PnP.PowerShell (>= 2.x)
    - Require admin privileges on both source and destination sites

.PARAMETER SourceUrl
    URL of the source SharePoint site.

.PARAMETER DestinationUrl
    URL of the destination SharePoint site.

.PARAMETER ClientId
    Client ID (AppID) of the Entra ID App Registration.

.PARAMETER Thumbprint
    Thumbprint of the certificate used for app-only authentication.

.PARAMETER TenantId
    Tenant ID (Directory ID GUID) of the Entra ID tenant.

.PARAMETER TemplatePath
    Local path to save or read the PnP XML template.

.PARAMETER MigrateContent
    Switch. If enabled, migrates files and document library content.

.EXAMPLE
    .\SPO-002_SiteMigration-ClassicToModern.ps1 `
        -SourceUrl "https://contoso.sharepoint.com/sites/OldIntranet" `
        -DestinationUrl "https://contoso.sharepoint.com/sites/NewIntranet" `
        -ClientId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
        -Thumbprint "AABBCC..." `
        -TenantId "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" `
        -MigrateContent
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true)] [string]$SourceUrl,
    [Parameter(Mandatory = $true)] [string]$DestinationUrl,
    [Parameter(Mandatory = $true)] [string]$ClientId,
    [Parameter(Mandatory = $true)] [string]$Thumbprint,
    [Parameter(Mandatory = $true)] [string]$TenantId,
    [Parameter(Mandatory = $false)][string]$TemplatePath = "$env:TEMP\PnPTemplate_$(Get-Date -Format 'yyyyMMdd').xml",
    [Parameter(Mandatory = $false)][switch]$MigrateContent
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
$LogFile = "$env:TEMP\SiteMigration_$(Get-Date -Format 'yyyyMMdd_HHmm').log"

#region ── Helpers ────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [ValidateSet('INFO','WARN','ERROR','SUCCESS')]$Level = 'INFO')
    $ts = Get-Date -Format 'HH:mm:ss'
    $colors = @{ INFO='Cyan'; WARN='Yellow'; ERROR='Red'; SUCCESS='Green' }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $colors[$Level]
    Add-Content -Path $LogFile -Value "[$ts][$Level] $Message"
}

function Connect-SPOSite {
    param([string]$Url)
    Connect-PnPOnline -Url $Url -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId
    Write-Log "Connected to: $Url" -Level SUCCESS
}
#endregion

#region ── Phase 1: Export Source PnP Template ────────────────────────────────
Write-Log "=== PHASE 1: Exporting PnP site template from source ==="
Connect-SPOSite -Url $SourceUrl

$extractConfig = @{
    Out                      = $TemplatePath
    IncludeAllClientSidePages= $true
    PersistBrandingFiles     = $true
    PersistPublishingFiles   = $true
    IncludeNativePublishingFiles = $true
    Handlers                 = @(
        "Lists", "Fields", "ContentTypes", "Features",
        "CustomActions", "Navigation", "Pages", "RegionalSettings",
        "SitePolicy", "WebSettings", "Workflows"
    )
}

try {
    Get-PnPSiteTemplate @extractConfig
    Write-Log "PnP template successfully exported to: $TemplatePath" -Level SUCCESS
} catch {
    Write-Log "Error exporting PnP template: $_" -Level ERROR
    exit 1
}
#endregion

#region ── Phase 2: Prepare Destination Site ──────────────────────────────────
Write-Log "=== PHASE 2: Validating and preparing destination site ==="

try {
    Connect-SPOSite -Url $DestinationUrl
    $web = Get-PnPWeb
    Write-Log "Destination site found: $($web.Title)"
} catch {
    Write-Log "Destination site not accessible: $_" -Level WARN
    Write-Log "Verify that the destination site exists and you have access." -Level ERROR
    exit 1
}

# Activate modern site features in destination
Write-Log "Activating modern experience features in destination..."
$modernFeatures = @(
    "B6917CB1-93A0-4B97-A84D-7CF49975D4EC", # Site Pages
    "F2A0DC96-E589-4E25-8465-40E02B4A7EF5"  # Modern experience
)

foreach ($featureId in $modernFeatures) {
    try {
        Enable-PnPFeature -Identity $featureId -Scope Web -Force -ErrorAction SilentlyContinue
        Write-Log "Feature $featureId activated." -Level SUCCESS
    } catch {
        Write-Log "Feature $featureId already active or unavailable." -Level WARN
    }
}
#endregion

#region ── Phase 3: Apply Template to Destination ──────────────────────────────
Write-Log "=== PHASE 3: Applying PnP template to destination ==="

$applyConfig = @{
    Path                  = $TemplatePath
    ClearNavigation       = $true
    OverwriteSystemPropertyBagValues = $true
}

if ($PSCmdlet.ShouldProcess($DestinationUrl, "Apply PnP template")) {
    try {
        Invoke-PnPSiteTemplate @applyConfig
        Write-Log "PnP template successfully applied." -Level SUCCESS
    } catch {
        Write-Log "Error applying template: $_" -Level ERROR
    }
}
#endregion

#region ── Phase 4: Migrate Content ───────────────────────────────────────────
if ($MigrateContent) {
    Write-Log "=== PHASE 4: Migrating files and library content ==="
    Connect-SPOSite -Url $SourceUrl

    $sourceLibraries = Get-PnPList | Where-Object {
        $_.BaseTemplate -eq 101 -and -not $_.Hidden
    }

    foreach ($library in $sourceLibraries) {
        Write-Log "Exporting library: $($library.Title)"
        $items = Get-PnPListItem -List $library.Title -PageSize 500

        foreach ($item in $items) {
            try {
                $fileUrl = $item["FileRef"]
                if (-not $fileUrl) { continue }

                $fileName  = Split-Path $fileUrl -Leaf
                $localTemp = "$env:TEMP\PnPMigration\$($library.Title)"
                if (-not (Test-Path $localTemp)) {
                    New-Item -ItemType Directory -Path $localTemp -Force | Out-Null
                }

                # Download file from source
                Get-PnPFile -Url $fileUrl -Path $localTemp -Filename $fileName -AsFile -Force

                # Upload file to destination
                Connect-SPOSite -Url $DestinationUrl
                Add-PnPFile -Path "$localTemp\$fileName" -Folder $library.Title -ErrorAction Stop

                # Restore metadata properties
                $destItem = Get-PnPListItem -List $library.Title -Query "<View><Query><Where><Eq><FieldRef Name='FileLeafRef'/><Value Type='Text'>$fileName</Value></Eq></Where></Query></View>"
                if ($destItem) {
                    $metaFields = @("Author","Created","Modified","Title")
                    $updates = @{}
                    foreach ($f in $metaFields) {
                        if ($item[$f]) { $updates[$f] = $item[$f] }
                    }
                    if ($updates.Count -gt 0) {
                        Set-PnPListItem -List $library.Title -Identity $destItem.Id -Values $updates | Out-Null
                    }
                }

                Connect-SPOSite -Url $SourceUrl
                Write-Log "  Migrated: $fileName" -Level SUCCESS

            } catch {
                Write-Log "  Error migrating '$($item['FileLeafRef'])': $_" -Level WARN
            }
        }
    }
}
#endregion

#region ── Phase 5: Replicate Groups and Permissions ──────────────────────────
Write-Log "=== PHASE 5: Replicating security groups and permissions ==="
Connect-SPOSite -Url $SourceUrl

$sourceGroups = Get-PnPGroup
Connect-SPOSite -Url $DestinationUrl

foreach ($group in $sourceGroups) {
    try {
        $existing = Get-PnPGroup -Identity $group.Title -ErrorAction SilentlyContinue
        if (-not $existing) {
            New-PnPGroup -Title $group.Title -Description $group.Description | Out-Null
            Write-Log "Group created: $($group.Title)" -Level SUCCESS
        }
    } catch {
        Write-Log "Error creating group '$($group.Title)': $_" -Level WARN
    }
}
#endregion

#region ── Final Summary ──────────────────────────────────────────────────────
Write-Log "========================================" -Level SUCCESS
Write-Log "MIGRATION PROCESS COMPLETED" -Level SUCCESS
Write-Log "Source      : $SourceUrl" -Level SUCCESS
Write-Log "Destination : $DestinationUrl" -Level SUCCESS
Write-Log "Log file    : $LogFile" -Level SUCCESS
Write-Log "========================================" -Level SUCCESS

Disconnect-PnPOnline
#endregion
