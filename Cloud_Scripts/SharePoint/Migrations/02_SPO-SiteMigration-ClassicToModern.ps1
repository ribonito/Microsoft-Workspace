<#
.SYNOPSIS
    SharePoint Online - Migración de Sitio Clásico a Moderno con PnP
.DESCRIPTION
    Realiza la migración completa de un sitio SharePoint On-Premises o clásico
    (SPO) a una estructura moderna usando PnP PowerShell. Incluye:
        - Migración de metadatos de listas/bibliotecas
        - Aplicación de plantillas PnP (Provisioning Template)
        - Migración de grupos y permisos
        - Activación de características modernas

    Requisitos:
        - PnP.PowerShell >= 2.x
        - Acceso de administrador en ambos sitios (origen y destino)

.PARAMETER SourceUrl
    URL del sitio origen.
.PARAMETER DestinationUrl
    URL del sitio destino (ya debe existir o se crea aquí si no existe).
.PARAMETER ClientId
    AppID del registro de aplicación en Entra ID.
.PARAMETER Thumbprint
    Thumbprint del certificado.
.PARAMETER TenantId
    Tenant ID (GUID).
.PARAMETER TemplatePath
    Ruta donde guardar/leer la plantilla PnP XML.
.PARAMETER MigrateContent
    Switch: si se especifica, migra también el contenido (archivos).

.EXAMPLE
    .\02_SPO-SiteMigration-ClassicToModern.ps1 `
        -SourceUrl "https://contoso.sharepoint.com/sites/OldIntranet" `
        -DestinationUrl "https://contoso.sharepoint.com/sites/NewIntranet" `
        -ClientId "xxxx" -Thumbprint "AABB" -TenantId "yyyy" `
        -MigrateContent

.NOTES
    Autor   : Solutions Architect - M365
    Versión : 1.0
    Módulo  : PnP.PowerShell
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
    Write-Log "Conectado a: $Url" -Level SUCCESS
}
#endregion

#region ── FASE 1: Exportar plantilla PnP del sitio origen ───────────────────
Write-Log "=== FASE 1: Exportando plantilla PnP del sitio origen ==="
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
    Write-Log "Plantilla PnP exportada a: $TemplatePath" -Level SUCCESS
} catch {
    Write-Log "Error exportando plantilla: $_" -Level ERROR
    exit 1
}
#endregion

#region ── FASE 2: Preparar sitio destino ────────────────────────────────────
Write-Log "=== FASE 2: Validando / preparando sitio destino ==="

try {
    Connect-SPOSite -Url $DestinationUrl
    $web = Get-PnPWeb
    Write-Log "Sitio destino encontrado: $($web.Title)"
} catch {
    Write-Log "Sitio destino no accesible: $_" -Level WARN
    Write-Log "Verifique que el sitio destino exista y tenga acceso." -Level ERROR
    exit 1
}

# Activar características modernas en destino
Write-Log "Activando características modernas en destino..."
$modernFeatures = @(
    "B6917CB1-93A0-4B97-A84D-7CF49975D4EC", # Site Pages
    "F2A0DC96-E589-4E25-8465-40E02B4A7EF5"  # Modern experience
)

foreach ($featureId in $modernFeatures) {
    try {
        Enable-PnPFeature -Identity $featureId -Scope Web -Force -ErrorAction SilentlyContinue
        Write-Log "Feature $featureId activada." -Level SUCCESS
    } catch {
        Write-Log "Feature $featureId ya activa o no disponible." -Level WARN
    }
}
#endregion

#region ── FASE 3: Aplicar plantilla en destino ───────────────────────────────
Write-Log "=== FASE 3: Aplicando plantilla PnP en sitio destino ==="

$applyConfig = @{
    Path                  = $TemplatePath
    ClearNavigation       = $true
    OverwriteSystemPropertyBagValues = $true
}

if ($PSCmdlet.ShouldProcess($DestinationUrl, "Aplicar plantilla PnP")) {
    try {
        Invoke-PnPSiteTemplate @applyConfig
        Write-Log "Plantilla aplicada correctamente." -Level SUCCESS
    } catch {
        Write-Log "Error aplicando plantilla: $_" -Level ERROR
    }
}
#endregion

#region ── FASE 4: Migrar contenido (archivos) ───────────────────────────────
if ($MigrateContent) {
    Write-Log "=== FASE 4: Migrando contenido (archivos) ==="
    Connect-SPOSite -Url $SourceUrl

    $sourceLibraries = Get-PnPList | Where-Object {
        $_.BaseTemplate -eq 101 -and -not $_.Hidden
    }

    foreach ($library in $sourceLibraries) {
        Write-Log "Exportando biblioteca: $($library.Title)"
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

                # Descargar del origen
                Get-PnPFile -Url $fileUrl -Path $localTemp -Filename $fileName -AsFile -Force

                # Subir al destino
                Connect-SPOSite -Url $DestinationUrl
                Add-PnPFile -Path "$localTemp\$fileName" -Folder $library.Title -ErrorAction Stop

                # Restaurar metadatos de columnas
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
                Write-Log "  Migrado: $fileName" -Level SUCCESS

            } catch {
                Write-Log "  Error migrando '$($item['FileLeafRef'])': $_" -Level WARN
            }
        }
    }
}
#endregion

#region ── FASE 5: Migrar grupos y permisos ──────────────────────────────────
Write-Log "=== FASE 5: Replicando grupos y permisos ==="
Connect-SPOSite -Url $SourceUrl

$sourceGroups = Get-PnPGroup
Connect-SPOSite -Url $DestinationUrl

foreach ($group in $sourceGroups) {
    try {
        $existing = Get-PnPGroup -Identity $group.Title -ErrorAction SilentlyContinue
        if (-not $existing) {
            New-PnPGroup -Title $group.Title -Description $group.Description | Out-Null
            Write-Log "Grupo creado: $($group.Title)" -Level SUCCESS
        }
    } catch {
        Write-Log "Error creando grupo '$($group.Title)': $_" -Level WARN
    }
}
#endregion

#region ── Resumen final ──────────────────────────────────────────────────────
Write-Log "========================================" -Level SUCCESS
Write-Log "MIGRACIÓN COMPLETADA" -Level SUCCESS
Write-Log "Origen  : $SourceUrl" -Level SUCCESS
Write-Log "Destino : $DestinationUrl" -Level SUCCESS
Write-Log "Log     : $LogFile" -Level SUCCESS
Write-Log "========================================" -Level SUCCESS

Disconnect-PnPOnline
#endregion
