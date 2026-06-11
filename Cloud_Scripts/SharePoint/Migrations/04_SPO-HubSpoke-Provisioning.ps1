<#
.SYNOPSIS
    SharePoint Online - Provisioning de Plantillas PnP para Arquitecturas Hub-Spoke
.DESCRIPTION
    Crea y despliega una arquitectura Hub-Spoke completa usando PnP Provisioning.
    Diseñado para arquitectos de soluciones que implementan gobernanza de información
    en M365. Incluye:
        - Creación de Hub Site raíz
        - Aprovisionamiento de sitios Spoke desde plantillas PnP XML
        - Asociación automática al Hub
        - Configuración de la barra de navegación del Hub
        - Aplicación de políticas de sharing y permisos
        - Registro en Site Script / Site Design opcional

    Requisitos:
        - PnP.PowerShell >= 2.x
        - Permisos: SharePoint Administrator, Global Reader (mínimo)

.PARAMETER TenantAdminUrl
    URL del Admin Center.
.PARAMETER ClientId / Thumbprint / TenantId
    Autenticación app-only.
.PARAMETER HubTitle
    Título del sitio Hub raíz.
.PARAMETER HubAlias
    Alias URL del Hub (sin espacios).
.PARAMETER SpokesDefinition
    Array de hashtables con la definición de cada spoke:
    @{ Title='IT'; Alias='IT-Dept'; Template='TeamSite'; PnPTemplate='C:\tmpl\IT.xml' }
.PARAMETER HubTemplatePath
    Ruta a la plantilla PnP XML del Hub.
.PARAMETER SharingPolicy
    Nivel de sharing: Disabled | ExistingExternalUserSharingOnly | ExternalUserSharingOnly | ExternalUserAndGuestSharing

.EXAMPLE
    $spokes = @(
        @{ Title='IT Department'; Alias='it-dept'; Template='TeamSite'; PnPTemplate='C:\IT.xml' },
        @{ Title='HR Portal';     Alias='hr-portal'; Template='CommunicationSite'; PnPTemplate='C:\HR.xml' }
    )

    .\04_SPO-HubSpoke-Provisioning.ps1 `
        -TenantAdminUrl "https://contoso-admin.sharepoint.com" `
        -ClientId "xxxx" -Thumbprint "AABB" -TenantId "yyyy" `
        -HubTitle "Corporate Intranet" -HubAlias "corporate-intranet" `
        -SpokesDefinition $spokes `
        -HubTemplatePath "C:\Hub.xml"

.NOTES
    Autor   : Solutions Architect - M365
    Versión : 1.0
    Módulo  : PnP.PowerShell
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

#region ── FASE 1: Crear sitio Hub ───────────────────────────────────────────
Write-Log "=== FASE 1: Creando sitio Hub ===" -Level PHASE
Connect-Admin

$tenantDomain = ($TenantAdminUrl -replace "-admin", "") -replace "https://", ""
$hubUrl = "https://$tenantDomain/sites/$HubAlias"

$existingHub = Get-PnPTenantSite -Url $hubUrl -ErrorAction SilentlyContinue

if (-not $existingHub) {
    Write-Log "Creando sitio Hub: $HubTitle ($hubUrl)"
    if ($PSCmdlet.ShouldProcess($hubUrl, "Crear Hub Site")) {
        New-PnPSite -Type CommunicationSite `
            -Title $HubTitle `
            -Url $hubUrl `
            -Lcid 3082 `
            -ErrorAction Stop | Out-Null
        Write-Log "Hub creado: $hubUrl" -Level SUCCESS
    }
} else {
    Write-Log "Hub ya existe: $hubUrl" -Level WARN
}

# Aplicar configuración al Hub site
Connect-Admin
Set-PnPTenantSite -Url $hubUrl `
    -SharingCapability $SharingPolicy `
    -DefaultLinkPermission View `
    -DefaultSharingLinkType Internal `
    -DisableSharingForNonOwnersStatus:$false | Out-Null
Write-Log "Configuración de sharing aplicada: $SharingPolicy" -Level SUCCESS

# Registrar como Hub Site
try {
    Register-PnPHubSite -Site $hubUrl -ErrorAction Stop
    Write-Log "Sitio registrado como Hub Site." -Level SUCCESS
} catch {
    Write-Log "Sitio ya es Hub o error al registrar: $_" -Level WARN
}
#endregion

#region ── FASE 2: Aplicar plantilla PnP al Hub ───────────────────────────────
if ($HubTemplatePath -and (Test-Path $HubTemplatePath)) {
    Write-Log "=== FASE 2: Aplicando plantilla al Hub ===" -Level PHASE
    Connect-Site -Url $hubUrl
    try {
        Invoke-PnPSiteTemplate -Path $HubTemplatePath -ClearNavigation
        Write-Log "Plantilla Hub aplicada correctamente." -Level SUCCESS
    } catch {
        Write-Log "Error aplicando plantilla Hub: $_" -Level ERROR
    }
}
#endregion

#region ── FASE 3: Crear y asociar sitios Spoke ──────────────────────────────
Write-Log "=== FASE 3: Aprovisionando sitios Spoke ===" -Level PHASE

$spokeUrls = @()
foreach ($spoke in $SpokesDefinition) {
    $spokeUrl = "https://$tenantDomain/sites/$($spoke.Alias)"
    $spokeUrls += $spokeUrl

    Connect-Admin
    $existingSpoke = Get-PnPTenantSite -Url $spokeUrl -ErrorAction SilentlyContinue

    if (-not $existingSpoke) {
        Write-Log "Creando spoke: $($spoke.Title) ($spokeUrl)"
        if ($PSCmdlet.ShouldProcess($spokeUrl, "Crear sitio Spoke")) {
            switch ($spoke.Template) {
                "CommunicationSite" {
                    New-PnPSite -Type CommunicationSite -Title $spoke.Title -Url $spokeUrl -Lcid 3082 | Out-Null
                }
                default {
                    New-PnPSite -Type TeamSite -Title $spoke.Title -Alias $spoke.Alias -Lcid 3082 | Out-Null
                }
            }
            Write-Log "Spoke creado: $spokeUrl" -Level SUCCESS
        }
    } else {
        Write-Log "Spoke ya existe: $spokeUrl" -Level WARN
    }

    # Aplicar plantilla PnP al spoke
    if ($spoke.PnPTemplate -and (Test-Path $spoke.PnPTemplate)) {
        Connect-Site -Url $spokeUrl
        try {
            Invoke-PnPSiteTemplate -Path $spoke.PnPTemplate -ClearNavigation
            Write-Log "  Plantilla aplicada al spoke '$($spoke.Title)'" -Level SUCCESS
        } catch {
            Write-Log "  Error en plantilla de spoke '$($spoke.Title)': $_" -Level WARN
        }
    }

    # Asociar spoke al Hub
    Connect-Site -Url $spokeUrl
    try {
        Add-PnPHubSiteAssociation -Site $spokeUrl -HubSite $hubUrl -ErrorAction Stop
        Write-Log "  Spoke '$($spoke.Title)' asociado al Hub." -Level SUCCESS
    } catch {
        Write-Log "  Error asociando '$($spoke.Title)' al Hub: $_" -Level WARN
    }

    # Configurar sharing del spoke
    Connect-Admin
    Set-PnPTenantSite -Url $spokeUrl `
        -SharingCapability $SharingPolicy `
        -DefaultLinkPermission View `
        -DefaultSharingLinkType Internal | Out-Null
}
#endregion

#region ── FASE 4: Configurar navegación del Hub ─────────────────────────────
Write-Log "=== FASE 4: Configurando navegación del Hub ===" -Level PHASE
Connect-Site -Url $hubUrl

# Limpiar navegación existente
$navItems = Get-PnPNavigationNode -Location TopNavigationBar
foreach ($item in $navItems) {
    Remove-PnPNavigationNode -Identity $item.Id -Force -ErrorAction SilentlyContinue
}

# Añadir nodos de navegación por cada spoke
foreach ($spoke in $SpokesDefinition) {
    $spokeUrl = "https://$tenantDomain/sites/$($spoke.Alias)"
    try {
        Add-PnPNavigationNode -Location TopNavigationBar -Title $spoke.Title -Url $spokeUrl | Out-Null
        Write-Log "  Nav añadida: $($spoke.Title)" -Level SUCCESS
    } catch {
        Write-Log "  Error en nav de '$($spoke.Title)': $_" -Level WARN
    }
}
#endregion

#region ── FASE 5: Crear Site Design (Site Script) para aprovisionamiento futuro
Write-Log "=== FASE 5: Registrando Site Design para reuse ===" -Level PHASE
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
        -Description "Plantilla de spoke para la arquitectura $HubTitle" | Out-Null
    Write-Log "Site Design registrado correctamente." -Level SUCCESS
} catch {
    Write-Log "Error registrando Site Design: $_" -Level WARN
}
#endregion

#region ── Resumen ────────────────────────────────────────────────────────────
Write-Log "============================================" -Level SUCCESS
Write-Log "ARQUITECTURA HUB-SPOKE COMPLETADA"           -Level SUCCESS
Write-Log "Hub       : $hubUrl"                         -Level SUCCESS
Write-Log "Spokes    : $($spokeUrls.Count) sitios"      -Level SUCCESS
$spokeUrls | ForEach-Object { Write-Log "  - $_" -Level SUCCESS }
Write-Log "Log       : $LogFile"                        -Level SUCCESS
Write-Log "============================================" -Level SUCCESS

Disconnect-PnPOnline
#endregion
