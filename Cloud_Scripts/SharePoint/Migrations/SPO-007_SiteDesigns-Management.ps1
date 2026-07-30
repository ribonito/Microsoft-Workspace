<#
.SYNOPSIS
    SPO-007 | SharePoint Online - Bulk Creation and Deployment of Site Designs with PnP.

.DESCRIPTION
    Automates the creation, management, and application of Site Designs and Site Scripts in M365.
    Key tool for M365 solution architects seeking to standardize site layouts in migration or onboarding projects.
    Includes:
        - Creation of Site Scripts from JSON files or defaults.
        - Deployment of custom tenant Site Designs.
        - Bulk application of Site Designs to existing lists/sites.
        - Exporting active Site Scripts.
        - Cleaning up orphan Site Scripts.

.PRODUCT
    SharePoint Online / PnP PowerShell

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - Module: PnP.PowerShell (>= 2.x)
    - Required role: SharePoint Administrator

.PARAMETER TenantAdminUrl
    URL of the SharePoint Admin Center.

.PARAMETER ClientId
    Client ID (AppID) of the Entra ID App Registration.

.PARAMETER Thumbprint
    Thumbprint of the certificate used for app-only authentication.

.PARAMETER TenantId
    Tenant ID (Directory ID GUID) of the Entra ID tenant.

.PARAMETER Mode
    Operation mode:
        Create       - Deploys new Site Script and Site Design.
        ApplyToSites - Applies a Site Design to multiple site collections.
        ExportAll    - Exports all Site Designs and Scripts to local folder.
        Cleanup      - Removes orphan Site Scripts not linked to any Site Design.

.PARAMETER SiteDesignName
    Name of the Site Design to create or apply.

.PARAMETER SiteScriptJsonPath
    Local path to the JSON Site Script configuration file.

.PARAMETER TargetSiteUrls
    Array of SharePoint site URLs to apply the Site Design to.

.PARAMETER WebTemplate
    Web template ID: 64 (Team Site), 68 (Communication Site).

.PARAMETER OutputPath
    Local directory path where reports and exported JSON files will be saved.

.EXAMPLE
    # Create new Site Design
    .\SPO-007_SiteDesigns-Management.ps1 `
        -TenantAdminUrl "https://contoso-admin.sharepoint.com" `
        -ClientId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
        -Thumbprint "AABBCC..." `
        -TenantId "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" `
        -Mode Create -SiteDesignName "Departmental Site Template" `
        -SiteScriptJsonPath "C:\SiteScript.json" -WebTemplate "64"
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory=$true)] [string]$TenantAdminUrl,
    [Parameter(Mandatory=$true)] [string]$ClientId,
    [Parameter(Mandatory=$true)] [string]$Thumbprint,
    [Parameter(Mandatory=$true)] [string]$TenantId,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Create","ApplyToSites","ExportAll","Cleanup")]
    [string]$Mode,

    [Parameter(Mandatory=$false)][string]  $SiteDesignName,
    [Parameter(Mandatory=$false)][string]  $SiteScriptJsonPath,
    [Parameter(Mandatory=$false)][string[]]$TargetSiteUrls = @(),
    [Parameter(Mandatory=$false)][ValidateSet("64","68")][string]$WebTemplate = "64",
    [Parameter(Mandatory=$false)][string]  $OutputPath = "$env:TEMP\SiteDesigns_$(Get-Date -Format 'yyyyMMdd_HHmm')"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$LogFile = "$OutputPath\sitedesigns.log"

#region ── Helpers ────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [ValidateSet('INFO','WARN','ERROR','SUCCESS','PHASE')]$Level = 'INFO')
    $ts  = Get-Date -Format 'HH:mm:ss'
    $clr = @{ INFO='Cyan'; WARN='Yellow'; ERROR='Red'; SUCCESS='Green'; PHASE='Magenta' }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $clr[$Level]
    Add-Content -Path $LogFile -Value "[$ts][$Level] $Message"
}
#endregion

Write-Log "Connecting to SharePoint Admin Center: $TenantAdminUrl" -Level PHASE
Connect-PnPOnline -Url $TenantAdminUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId

#region ── Mode: Create ────────────────────────────────────────────────────────
if ($Mode -eq "Create") {
    Write-Log "=== CREATING SITE SCRIPT + SITE DESIGN ===" -Level PHASE

    if (-not $SiteDesignName) {
        Write-Log "-SiteDesignName parameter is required for Create mode." -Level ERROR
        exit 1
    }

    if (-not $SiteScriptJsonPath -or -not (Test-Path $SiteScriptJsonPath)) {
        Write-Log "No SiteScriptJsonPath specified. Using default template." -Level WARN

        $defaultScript = @{
            '$schema' = "schema.json"
            actions   = @(
                @{ verb = "setSiteExternalSharingCapability"; capability = "ExistingExternalUserSharingOnly" }
                @{ verb = "activateSPFeature"; featureId = "b6917cb1-93a0-4b97-a84d-7cf49975d4ec"; featureDefinitionScope = "Web" }
                @{
                    verb  = "createSPList"
                    templateType = 100
                    title = "Migration Tracker"
                    subactions = @(
                        @{ verb = "setTitle"; title = "Migration Tracker" }
                        @{ verb = "addSPField"; fieldType = "Text"; displayName = "Status"; isRequired = $false; addToDefaultView = $true }
                        @{ verb = "addSPField"; fieldType = "Note"; displayName = "Notes";  isRequired = $false; addToDefaultView = $true }
                    )
                }
                @{
                    verb     = "addNavLink"
                    url      = "/Lists/Migration%20Tracker"
                    displayName = "Migration Tracker"
                    isWebRelative = $false
                }
            )
            bindata = @{}
            version = 1
        }
        $jsonContent = $defaultScript | ConvertTo-Json -Depth 10
        $SiteScriptJsonPath = "$OutputPath\DefaultSiteScript.json"
        $jsonContent | Out-File $SiteScriptJsonPath -Encoding UTF8
        Write-Log "Default site script saved to: $SiteScriptJsonPath" -Level INFO
    }

    $scriptJson = Get-Content $SiteScriptJsonPath -Raw

    try {
        if ($PSCmdlet.ShouldProcess($SiteDesignName, "Create Site Script")) {
            $siteScript = Add-PnPSiteScript -Title "$SiteDesignName Script" -Content $scriptJson
            Write-Log "Site Script created successfully: ID=$($siteScript.Id)" -Level SUCCESS

            $siteDesign = Add-PnPSiteDesign `
                -Title $SiteDesignName `
                -SiteScripts @($siteScript.Id) `
                -WebTemplate $WebTemplate `
                -Description "Site Design deployed via M365 script - $(Get-Date -Format 'yyyy-MM-dd')" `
                -ThumbnailUrl ""

            Write-Log "Site Design created successfully: ID=$($siteDesign.Id)" -Level SUCCESS
            Write-Log "Details:" -Level INFO
            Write-Log "  Title      : $($siteDesign.Title)"
            Write-Log "  ID         : $($siteDesign.Id)"
            Write-Log "  Template   : $($siteDesign.WebTemplate)"
            Write-Log "  Script IDs : $($siteDesign.SiteScriptIds -join ', ')"

            # Save created design details
            [PSCustomObject]@{
                DesignName = $siteDesign.Title
                DesignId   = $siteDesign.Id
                ScriptId   = $siteScript.Id
                Template   = $WebTemplate
                CreatedAt  = Get-Date -Format 'yyyy-MM-dd HH:mm'
            } | ConvertTo-Json | Out-File "$OutputPath\CreatedDesign_$($siteDesign.Id).json" -Encoding UTF8
        }
    } catch {
        Write-Log "Error creating Site Script/Design: $_" -Level ERROR
    }
}
#endregion

#region ── Mode: ApplyToSites ──────────────────────────────────────────────────
if ($Mode -eq "ApplyToSites") {
    Write-Log "=== APPLYING SITE DESIGN TO SITES ===" -Level PHASE

    if (-not $SiteDesignName) { Write-Log "-SiteDesignName parameter is required." -Level ERROR; exit 1 }
    if ($TargetSiteUrls.Count -eq 0) { Write-Log "-TargetSiteUrls parameter is required." -Level ERROR; exit 1 }

    $design = Get-PnPSiteDesign | Where-Object { $_.Title -eq $SiteDesignName }
    if (-not $design) {
        Write-Log "Site Design '$SiteDesignName' not found in tenant." -Level ERROR
        exit 1
    }

    Write-Log "Site Design ID: $($design.Id) | Sites to process: $($TargetSiteUrls.Count)"
    $applyResults = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($siteUrl in $TargetSiteUrls) {
        Write-Log "Applying to: $siteUrl"
        try {
            if ($PSCmdlet.ShouldProcess($siteUrl, "Apply Site Design '$SiteDesignName'")) {
                # Invoke from the tenant-admin connection, explicitly targeting the site.
                $result = Invoke-PnPSiteDesign -Identity $design.Id -WebUrl $siteUrl
                Write-Log "  ✔ Applied successfully." -Level SUCCESS
                $applyResults.Add([PSCustomObject]@{
                    SiteUrl    = $siteUrl
                    DesignId   = $design.Id
                    Status     = "SUCCESS"
                    AppliedAt  = Get-Date -Format 'yyyy-MM-dd HH:mm'
                })
            }
        } catch {
            Write-Log "  ✖ Error applying to $($siteUrl): $_" -Level ERROR
            $applyResults.Add([PSCustomObject]@{
                SiteUrl    = $siteUrl
                DesignId   = $design.Id
                Status     = "ERROR"
                AppliedAt  = Get-Date -Format 'yyyy-MM-dd HH:mm'
                Detail     = $_.ToString()
            })
        }
    }

    $applyResults | Export-Csv "$OutputPath\ApplyResults.csv" -NoTypeInformation -Encoding UTF8
    Write-Log "Results saved to: $OutputPath\ApplyResults.csv" -Level SUCCESS
}
#endregion

#region ── Mode: ExportAll ─────────────────────────────────────────────────────
if ($Mode -eq "ExportAll") {
    Write-Log "=== EXPORTING TENANT SITE DESIGNS AND SCRIPTS ===" -Level PHASE

    Connect-PnPOnline -Url $TenantAdminUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId

    $allDesigns = Get-PnPSiteDesign
    $allScripts = Get-PnPSiteScript

    Write-Log "Site Designs found: $($allDesigns.Count)"
    Write-Log "Site Scripts found: $($allScripts.Count)"

    # Export catalog list
    $allDesigns | Select-Object Title, Id, WebTemplate, Description, SiteScriptIds, IsDefault, PreviewImageUrl |
        Export-Csv "$OutputPath\Catalog_SiteDesigns.csv" -NoTypeInformation -Encoding UTF8

    # Export actual JSON contents of each script
    $scriptsDir = "$OutputPath\SiteScripts"
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

    foreach ($script in $allScripts) {
        try {
            $scriptContent = Get-PnPSiteScript -Identity $script.Id
            $safeName = $script.Title -replace '[\\/:*?"<>|]', '_'
            $scriptContent.Content | Out-File "$scriptsDir\$safeName`_$($script.Id).json" -Encoding UTF8
            Write-Log "  Exported Script: '$($script.Title)'" -Level SUCCESS
        } catch {
            Write-Log "  Error exporting script '$($script.Title)': $_" -Level WARN
        }
    }

    Write-Log "Scripts successfully exported to: $scriptsDir" -Level SUCCESS
}
#endregion

#region ── Mode: Cleanup ───────────────────────────────────────────────────────
if ($Mode -eq "Cleanup") {
    Write-Log "=== CLEANING UP ORPHANED SITE SCRIPTS ===" -Level PHASE
    Connect-PnPOnline -Url $TenantAdminUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId

    $allDesigns = Get-PnPSiteDesign
    $allScripts = Get-PnPSiteScript

    # Find Site Scripts not referenced by any Site Design
    $referencedScriptIds = $allDesigns | ForEach-Object { $_.SiteScriptIds } | Where-Object { $_ } | Sort-Object -Unique
    $orphanScripts = $allScripts | Where-Object { $_.Id.Guid -notin $referencedScriptIds }

    Write-Log "Orphaned scripts detected: $($orphanScripts.Count)"
    foreach ($orphan in $orphanScripts) {
        Write-Log "  Orphan: '$($orphan.Title)' (ID: $($orphan.Id))" -Level WARN
        if ($PSCmdlet.ShouldProcess($orphan.Title, "Remove orphaned Site Script")) {
            try {
                Remove-PnPSiteScript -Identity $orphan.Id -Force
                Write-Log "  ✔ Removed." -Level SUCCESS
            } catch {
                Write-Log "  ✖ Error removing orphaned script: $_" -Level ERROR
            }
        }
    }
}
#endregion

Write-Log "=== SITE DESIGNS OPERATION '$Mode' COMPLETED ===" -Level SUCCESS
Write-Log "Output directory: $OutputPath" -Level SUCCESS
Disconnect-PnPOnline
