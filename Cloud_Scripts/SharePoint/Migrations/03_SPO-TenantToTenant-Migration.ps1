<#
.SYNOPSIS
    SharePoint Online - Migración Tenant-to-Tenant (T2T) con PnP
.DESCRIPTION
    Orquesta la migración completa de sitios entre dos tenants de Microsoft 365.
    Cubre el flujo recomendado por Microsoft para migraciones T2T:
        1. Export de plantilla PnP en tenant origen
        2. Exportación de contenido a SharePoint Package (SPKG) vía CSOM
        3. Importación en tenant destino con Invoke-PnPSiteTemplate
        4. Replicación de permisos (usuarios mapeados en un CSV)
        5. Verificación post-migración

    Requisitos:
        - PnP.PowerShell >= 2.x en AMBOS tenants
        - Dos registros de aplicación (uno por tenant)
        - Certificados instalados localmente
        - CSV de mapeo de usuarios: SourceUPN, DestinationUPN

.PARAMETER SourceTenantAdminUrl
    URL Admin Center del tenant origen.
.PARAMETER DestTenantAdminUrl
    URL Admin Center del tenant destino.
.PARAMETER SourceSiteUrl
    URL del sitio a migrar en el tenant origen.
.PARAMETER DestSiteUrl
    URL del sitio destino en el tenant destino.
.PARAMETER SourceClientId / DestClientId
    App IDs de las aplicaciones registradas en cada tenant.
.PARAMETER SourceThumbprint / DestThumbprint
    Thumbprints de los certificados de autenticación.
.PARAMETER SourceTenantId / DestTenantId
    Tenant IDs (GUID).
.PARAMETER UserMappingCsv
    CSV con columnas: SourceUPN, DestinationUPN
.PARAMETER WorkingFolder
    Carpeta temporal para archivos de migración.

.EXAMPLE
    .\03_SPO-TenantToTenant-Migration.ps1 `
        -SourceTenantAdminUrl "https://sourcecontoso-admin.sharepoint.com" `
        -DestTenantAdminUrl   "https://destcontoso-admin.sharepoint.com" `
        -SourceSiteUrl "https://sourcecontoso.sharepoint.com/sites/HR" `
        -DestSiteUrl   "https://destcontoso.sharepoint.com/sites/HR" `
        -SourceClientId "src-app-id" -SourceThumbprint "SRC..." -SourceTenantId "src-tid" `
        -DestClientId   "dst-app-id" -DestThumbprint   "DST..." -DestTenantId   "dst-tid" `
        -UserMappingCsv "C:\T2T\UserMapping.csv"

.NOTES
    Autor   : Solutions Architect - M365
    Versión : 1.0
    Módulo  : PnP.PowerShell
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    # Tenant Origen
    [Parameter(Mandatory=$true)][string]$SourceTenantAdminUrl,
    [Parameter(Mandatory=$true)][string]$SourceSiteUrl,
    [Parameter(Mandatory=$true)][string]$SourceClientId,
    [Parameter(Mandatory=$true)][string]$SourceThumbprint,
    [Parameter(Mandatory=$true)][string]$SourceTenantId,

    # Tenant Destino
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

# Cargar mapeo de usuarios si se proporcionó
$userMap = $null
if ($UserMappingCsv -and (Test-Path $UserMappingCsv)) {
    $userMap = Import-Csv $UserMappingCsv
    Write-Log "Mapeo de usuarios cargado: $($userMap.Count) entradas."
}

$migrationResults = [System.Collections.Generic.List[PSObject]]::new()
#endregion

#region ── FASE 1: Análisis del sitio origen ─────────────────────────────────
Write-Log "=== FASE 1: Análisis del sitio ORIGEN ===" -Level PHASE
ConnectSource

$sourceWeb     = Get-PnPWeb -Includes Title, Description, Language, RegionalSettings
$sourceLists   = Get-PnPList | Where-Object { -not $_.Hidden }
$sourcePages   = Get-PnPListItem -List "Site Pages" -PageSize 200 -ErrorAction SilentlyContinue

Write-Log "Sitio origen: $($sourceWeb.Title)"
Write-Log "Listas/Bibliotecas: $($sourceLists.Count)"
Write-Log "Páginas: $($sourcePages.Count)"
#endregion

#region ── FASE 2: Exportar plantilla PnP del origen ─────────────────────────
Write-Log "=== FASE 2: Exportando plantilla PnP ===" -Level PHASE

$handlers = "Lists,Fields,ContentTypes,CustomActions,Features,Files,Navigation,Pages,PageContents,Publishing,RegionalSettings,SearchSettings,SitePolicy,SupportedUILanguages,WebSettings,Workflows"

try {
    Get-PnPSiteTemplate -Out $TemplatePath -Handlers $handlers `
        -IncludeAllClientSidePages `
        -PersistBrandingFiles `
        -PersistPublishingFiles `
        -ErrorAction Stop
    Write-Log "Plantilla exportada: $TemplatePath" -Level SUCCESS
} catch {
    Write-Log "Error exportando plantilla: $_" -Level ERROR
    exit 1
}
#endregion

#region ── FASE 3: Exportar archivos/contenido del origen ────────────────────
Write-Log "=== FASE 3: Descargando contenido (archivos) ===" -Level PHASE

foreach ($list in $sourceLists | Where-Object { $_.BaseTemplate -eq 101 }) {
    $localLibPath = "$WorkingFolder\Content\$($list.Title)"
    if (-not (Test-Path $localLibPath)) { New-Item -ItemType Directory -Path $localLibPath -Force | Out-Null }

    Write-Log "Exportando biblioteca: $($list.Title) ($($list.ItemCount) elementos)"
    $items = Get-PnPListItem -List $list.Title -PageSize 500 -Fields "FileRef","FileLeafRef","Modified","Author"

    foreach ($item in $items) {
        $fileRef = $item["FileRef"]
        if (-not $fileRef) { continue }
        try {
            Get-PnPFile -Url $fileRef -Path $localLibPath -FileName $item["FileLeafRef"] -AsFile -Force
        } catch {
            Write-Log "  No se pudo descargar: $fileRef - $_" -Level WARN
            $migrationResults.Add([PSCustomObject]@{
                Status    = "WARN"
                Type      = "File"
                Source    = $fileRef
                Detail    = $_.ToString()
            })
        }
    }
}
Write-Log "Descarga completada. Archivos en: $WorkingFolder\Content" -Level SUCCESS
#endregion

#region ── FASE 4: Crear sitio destino (si no existe) ────────────────────────
Write-Log "=== FASE 4: Preparando sitio DESTINO ===" -Level PHASE

Connect-PnPOnline -Url $DestTenantAdminUrl -ClientId $DestClientId -Thumbprint $DestThumbprint -Tenant $DestTenantId

$destAlias = ($DestSiteUrl -split "/sites/")[1]
$existingDestSite = Get-PnPTenantSite -Url $DestSiteUrl -ErrorAction SilentlyContinue

if (-not $existingDestSite) {
    Write-Log "Creando sitio destino: $DestSiteUrl"
    if ($PSCmdlet.ShouldProcess($DestSiteUrl, "Crear sitio destino")) {
        New-PnPSite -Type TeamSite `
            -Title $sourceWeb.Title `
            -Alias $destAlias `
            -Description $sourceWeb.Description `
            -Lcid $sourceWeb.Language `
            -ErrorAction Stop | Out-Null
        Write-Log "Sitio destino creado." -Level SUCCESS
    }
} else {
    Write-Log "Sitio destino ya existe: $DestSiteUrl" -Level WARN
}
#endregion

#region ── FASE 5: Aplicar plantilla en destino ───────────────────────────────
Write-Log "=== FASE 5: Aplicando plantilla PnP en destino ===" -Level PHASE
ConnectDest

if ($PSCmdlet.ShouldProcess($DestSiteUrl, "Aplicar plantilla PnP")) {
    try {
        Invoke-PnPSiteTemplate -Path $TemplatePath `
            -ClearNavigation `
            -OverwriteSystemPropertyBagValues
        Write-Log "Plantilla aplicada correctamente." -Level SUCCESS
    } catch {
        Write-Log "Error aplicando plantilla: $_" -Level ERROR
    }
}
#endregion

#region ── FASE 6: Subir contenido al destino ────────────────────────────────
Write-Log "=== FASE 6: Subiendo contenido al destino ===" -Level PHASE

$contentRoot = "$WorkingFolder\Content"
if (Test-Path $contentRoot) {
    $localLibs = Get-ChildItem -Path $contentRoot -Directory
    foreach ($lib in $localLibs) {
        $files = Get-ChildItem -Path $lib.FullName -File -Recurse
        Write-Log "Subiendo $($files.Count) archivo(s) a biblioteca '$($lib.Name)'"
        foreach ($file in $files) {
            try {
                $relativePath = $file.FullName.Substring($lib.FullName.Length + 1)
                $destFolder   = "$($lib.Name)/" + ($relativePath | Split-Path -Parent)
                Add-PnPFile -Path $file.FullName -Folder $destFolder -ErrorAction Stop | Out-Null
                $migrationResults.Add([PSCustomObject]@{
                    Status = "SUCCESS"; Type = "File"; Source = $file.FullName; Detail = "OK"
                })
            } catch {
                Write-Log "  Error subiendo '$($file.Name)': $_" -Level WARN
                $migrationResults.Add([PSCustomObject]@{
                    Status = "ERROR"; Type = "File"; Source = $file.FullName; Detail = $_.ToString()
                })
            }
        }
    }
}
#endregion

#region ── FASE 7: Mapear permisos al destino ────────────────────────────────
Write-Log "=== FASE 7: Replicando permisos con mapeo de usuarios ===" -Level PHASE

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
            Write-Log "  Añadido $destUpn al grupo '$($group.Title)'" -Level SUCCESS
        } catch {
            Write-Log "  No se pudo añadir $destUpn al grupo '$($group.Title)': $_" -Level WARN
        }
    }
}
#endregion

#region ── FASE 8: Informe post-migración ────────────────────────────────────
Write-Log "=== FASE 8: Generando informe de migración ===" -Level PHASE

$migrationResults | Export-Csv $ReportPath -NoTypeInformation -Encoding UTF8

$successCount = ($migrationResults | Where-Object { $_.Status -eq 'SUCCESS' }).Count
$errorCount   = ($migrationResults | Where-Object { $_.Status -eq 'ERROR'   }).Count
$warnCount    = ($migrationResults | Where-Object { $_.Status -eq 'WARN'    }).Count

Write-Log "======================================"   -Level SUCCESS
Write-Log "MIGRACIÓN T2T COMPLETADA"                -Level SUCCESS
Write-Log "  ✅ Éxitos  : $successCount"             -Level SUCCESS
Write-Log "  ⚠️  Avisos  : $warnCount"               -Level WARN
Write-Log "  ❌ Errores : $errorCount"               -Level ERROR
Write-Log "  Informe   : $ReportPath"               -Level SUCCESS
Write-Log "======================================"   -Level SUCCESS

Disconnect-PnPOnline
#endregion
