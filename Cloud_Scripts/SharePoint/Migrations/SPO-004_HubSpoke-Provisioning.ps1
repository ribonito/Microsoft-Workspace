<#
.SYNOPSIS
    SPO-004 | SharePoint Online - Provisioning PnP Templates for Hub-Spoke Architectures.

.DESCRIPTION
    Creates and deploys a complete Hub-Spoke architecture using PnP Provisioning.
    Designed for solution architects implementing information governance in M365.
    Includes:
        - Creation of the root Hub Site
        - Provisioning of Spoke sites from PnP XML templates
        - Automatic hub site association
        - Hub navigation configuration
        - External sharing policy configuration
        - Optional Site Script / Site Design registration

.PRODUCT
    SharePoint Online / PnP PowerShell

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - Module: PnP.PowerShell (>= 2.x)
    - Required permissions: SharePoint Administrator, Global Reader (minimum)

.PARAMETER TenantAdminUrl
    URL of the SharePoint Admin Center.

.PARAMETER ClientId
    Client ID (AppID) of the Entra ID App Registration.

.PARAMETER Thumbprint
    Thumbprint of the certificate used for app-only authentication.

.PARAMETER TenantId
    Tenant ID (Directory ID GUID) of the Entra ID tenant.

.PARAMETER HubTitle
    Title of the root Hub site.

.PARAMETER HubAlias
    URL alias of the Hub (no spaces).

.PARAMETER SpokesDefinition
    Array of hashtables defining each spoke:
    @{ Title='IT'; Alias='IT-Dept'; Template='TeamSite'; PnPTemplate='C:\tmpl\IT.xml' }

.PARAMETER HubTemplatePath
    Local path to the Hub PnP XML template.

.PARAMETER SharingPolicy
    External sharing level: Disabled | ExistingExternalUserSharingOnly | ExternalUserSharingOnly | ExternalUserAndGuestSharing

.EXAMPLE
    $spokes = @(
        @{ Title='IT Department'; Alias='it-dept'; Template='TeamSite'; PnPTemplate='C:\IT.xml' },
        @{ Title='HR Portal';     Alias='hr-portal'; Template='CommunicationSite'; PnPTemplate='C:\HR.xml' }
    )

    .\SPO-004_HubSpoke-Provisioning.ps1 `
        -TenantAdminUrl "https://contoso-admin.sharepoint.com" `
        -ClientId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
        -Thumbprint "AABBCC..." `
        -TenantId "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" `
        -HubTitle "Corporate Intranet" -HubAlias "corporate-intranet" `
        -SpokesDefinition $spokes `
        -HubTemplatePath "C:\Hub.xml"
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory=$true)] [string]$TenantAdminUrl,
    [Parameter(Mandatory=$true)] [string]$ClientId,
    [Parameter(Mandatory=$true)] [string]$Thumbprint,
    [Parameter(Mandatory=$true)] [string]$TenantId,

    [Parameter(Mandatory=$true)] [string]$HubTitle,
    [Parameter(Mandatory=$true)] [string]$HubAlias,
    [Parameter(Mandatory=$false)][string]$HubTemplatePath,
    [Parameter(Mandatory=$false)][array] $SpokesDefinition = @(),
    [Parameter(Mandatory=$false)][ValidateSet(
        "Disabled","ExistingExternalUserSharingOnly",
        "ExternalUserSharingOnly","ExternalUserAndGuestSharing"
    )][string]$SharingPolicy = "ExistingExternalUserSharingOnly"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
$LogFile = "$env:TEMP\HubSpoke_Provisioning_$(Get-Date -Format 'yyyyMMdd_HHmm').log"

#region ── Helpers ────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [ValidateSet('INFO','WARN','ERROR','SUCCESS','PHASE')]$Level = 'INFO')
    $ts  = Get-Date -Format 'HH:mm:ss'
    $clr = @{ INFO='Cyan'; WARN='Yellow'; ERROR='Red'; SUCCESS='Green'; PHASE='Magenta' }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $clr[$Level]
    Add-Content -Path $LogFile -Value "[$ts][$Level] $Message"
}

function Connect-Admin {
    Connect-PnPOnline -Url $TenantAdminUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId
}

function Connect-Site {
    param([string]$Url)
    Connect-PnPOnline -Url $Url -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId
}
#endregion

#region ── Phase 1: Create Hub Site ───────────────────────────────────────────
Write-Log "=== PHASE 1: Creating Hub Site ===" -Level PHASE
Connect-Admin

$tenantDomain = ($TenantAdminUrl -replace "-admin", "") -replace "https://", ""
$hubUrl = "https://$tenantDomain/sites/$HubAlias"

$existingHub = Get-PnPTenantSite -Url $hubUrl -ErrorAction SilentlyContinue

if (-not $existingHub) {
    Write-Log "Creating Hub site: $HubTitle ($hubUrl)"
    if ($PSCmdlet.ShouldProcess($hubUrl, "Create Hub Site")) {
        New-PnPSite -Type CommunicationSite `
            -Title $HubTitle `
            -Url $hubUrl `
            -Lcid 1033 `
            -ErrorAction Stop | Out-Null
        Write-Log "Hub created: $hubUrl" -Level SUCCESS
    }
} else {
    Write-Log "Hub site already exists: $hubUrl" -Level WARN
}

# Apply sharing policy configuration to the Hub site
Connect-Admin
Set-PnPTenantSite -Url $hubUrl `
    -SharingCapability $SharingPolicy `
    -DefaultLinkPermission View `
    -DefaultSharingLinkType Internal `
    -DisableSharingForNonOwnersStatus:$false | Out-Null
Write-Log "Sharing policy applied: $SharingPolicy" -Level SUCCESS

# Register as Hub Site
try {
    Register-PnPHubSite -Site $hubUrl -ErrorAction Stop
    Write-Log "Registered as a Hub Site." -Level SUCCESS
} catch {
    Write-Log "Site is already a Hub or error during registration: $_" -Level WARN
}
#endregion

#region ── Phase 2: Apply PnP Template to Hub ─────────────────────────────────
if ($HubTemplatePath -and (Test-Path $HubTemplatePath)) {
    Write-Log "=== PHASE 2: Applying PnP template to Hub ===" -Level PHASE
    Connect-Site -Url $hubUrl
    try {
        Invoke-PnPSiteTemplate -Path $HubTemplatePath -ClearNavigation
        Write-Log "Hub template applied successfully." -Level SUCCESS
    } catch {
        Write-Log "Error applying Hub template: $_" -Level ERROR
    }
}
#endregion

#region ── Phase 3: Create and Associate Spoke Sites ──────────────────────────
Write-Log "=== PHASE 3: Provisioning Spoke Sites ===" -Level PHASE

$spokeUrls = @()
foreach ($spoke in $SpokesDefinition) {
    $spokeUrl = "https://$tenantDomain/sites/$($spoke.Alias)"
    $spokeUrls += $spokeUrl

    Connect-Admin
    $existingSpoke = Get-PnPTenantSite -Url $spokeUrl -ErrorAction SilentlyContinue

    if (-not $existingSpoke) {
        Write-Log "Creating spoke: $($spoke.Title) ($spokeUrl)"
        if ($PSCmdlet.ShouldProcess($spokeUrl, "Create Spoke Site")) {
            switch ($spoke.Template) {
                "CommunicationSite" {
                    New-PnPSite -Type CommunicationSite -Title $spoke.Title -Url $spokeUrl -Lcid 1033 | Out-Null
                }
                default {
                    New-PnPSite -Type TeamSite -Title $spoke.Title -Alias $spoke.Alias -Lcid 1033 | Out-Null
                }
            }
            Write-Log "Spoke created: $spokeUrl" -Level SUCCESS
        }
    } else {
        Write-Log "Spoke site already exists: $spokeUrl" -Level WARN
    }

    # Apply PnP template to the spoke
    if ($spoke.PnPTemplate -and (Test-Path $spoke.PnPTemplate)) {
        Connect-Site -Url $spokeUrl
        try {
            Invoke-PnPSiteTemplate -Path $spoke.PnPTemplate -ClearNavigation
            Write-Log "  Template applied to spoke '$($spoke.Title)'" -Level SUCCESS
        } catch {
            Write-Log "  Error applying template to spoke '$($spoke.Title)': $_" -Level WARN
        }
    }

    # Associate spoke to Hub
    Connect-Site -Url $spokeUrl
    try {
        Add-PnPHubSiteAssociation -Site $spokeUrl -HubSite $hubUrl -ErrorAction Stop
        Write-Log "  Associated spoke '$($spoke.Title)' to Hub." -Level SUCCESS
    } catch {
        Write-Log "  Error associating '$($spoke.Title)' to Hub: $_" -Level WARN
    }

    # Configure sharing policy of the spoke
    Connect-Admin
    Set-PnPTenantSite -Url $spokeUrl `
        -SharingCapability $SharingPolicy `
        -DefaultLinkPermission View `
        -DefaultSharingLinkType Internal | Out-Null
}
#endregion

#region ── Phase 4: Configure Hub Navigation ──────────────────────────────────
Write-Log "=== PHASE 4: Configuring Hub site navigation ===" -Level PHASE
Connect-Site -Url $hubUrl

# Clear existing navigation nodes
$navItems = Get-PnPNavigationNode -Location TopNavigationBar
foreach ($item in $navItems) {
    Remove-PnPNavigationNode -Identity $item.Id -Force -ErrorAction SilentlyContinue
}

# Add navigation nodes for each spoke
foreach ($spoke in $SpokesDefinition) {
    $spokeUrl = "https://$tenantDomain/sites/$($spoke.Alias)"
    try {
        Add-PnPNavigationNode -Location TopNavigationBar -Title $spoke.Title -Url $spokeUrl | Out-Null
        Write-Log "  Added navigation node: $($spoke.Title)" -Level SUCCESS
    } catch {
        Write-Log "  Error creating navigation node for '$($spoke.Title)': $_" -Level WARN
    }
}
#endregion

#region ── Phase 5: Register Site Design and Script ───────────────────────────
Write-Log "=== PHASE 5: Registering Site Design for reuse ===" -Level PHASE
Connect-Admin

$siteScript = @"
{
    "\$schema": "schema.json",
    "actions": [
        { "verb": "joinHubSite", "hubSiteId": "" },
        { "verb": "setSiteExternalSharingCapability", "capability": "Disabled" },
        { "verb": "activateSPFeature", "featureId": "b6917cb1-93a0-4b97-a84d-7cf49975d4ec", "featureDefinitionScope": "Web" }
    ],
    "bindata": {},
    "version": 1
}
"@

try {
    $script = Add-PnPSiteScript -Title "HubSpoke-BaseScript" -Content $siteScript -ErrorAction Stop
    Add-PnPSiteDesign -Title "$HubTitle - Spoke Template" `
        -SiteScripts $script.Id `
        -WebTemplate "64" `
        -Description "Spoke template for $HubTitle architecture" | Out-Null
    Write-Log "Site Design registered successfully." -Level SUCCESS
} catch {
    Write-Log "Error registering Site Design: $_" -Level WARN
}
#endregion

#region ── Final Summary ──────────────────────────────────────────────────────
Write-Log "============================================" -Level SUCCESS
Write-Log "HUB-SPOKE PROVISIONING COMPLETED"            -Level SUCCESS
Write-Log "Hub Site  : $hubUrl"                         -Level SUCCESS
Write-Log "Spokes    : $($spokeUrls.Count) sites"       -Level SUCCESS
$spokeUrls | ForEach-Object { Write-Log "  - $_" -Level SUCCESS }
Write-Log "Log file  : $LogFile"                        -Level SUCCESS
Write-Log "============================================" -Level SUCCESS

Disconnect-PnPOnline
#endregion
