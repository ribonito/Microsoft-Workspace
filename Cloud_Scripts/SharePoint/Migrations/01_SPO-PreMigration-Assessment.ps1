<#
.SYNOPSIS
    SharePoint Online - Pre-Migration Assessment (PnP Modern)
.DESCRIPTION
    Genera un inventario completo de sitios, bibliotecas, permisos y contenido
    previo a una migración. Útil para arquitectos de soluciones M365 en proyectos
    de migración On-Premises → SPO o Tenant-to-Tenant.

    Requisitos:
        - PnP.PowerShell >= 2.x  (Install-Module PnP.PowerShell)
        - App Registration con permisos: Sites.Read.All, User.Read.All (o cuenta de servicio admin)

.PARAMETER TenantAdminUrl
    URL del Admin Center (ej: https://contoso-admin.sharepoint.com)
.PARAMETER OutputPath
    Ruta local donde se guardarán los informes CSV.
.PARAMETER ClientId
    AppID del registro de aplicación en Entra ID.
.PARAMETER Thumbprint
    Thumbprint del certificado para autenticación con app-only.
.PARAMETER TenantId
    Tenant ID (GUID) del directorio Entra ID.

.EXAMPLE
    .\01_SPO-PreMigration-Assessment.ps1 `
        -TenantAdminUrl "https://contoso-admin.sharepoint.com" `
        -ClientId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
        -Thumbprint "AABBCC..." `
        -TenantId "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" `
        -OutputPath "C:\MigrationReports"

.NOTES
    Autor   : Solutions Architect - M365
    Versión : 1.0
    Módulo  : PnP.PowerShell
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
        Write-Log "Directorio de salida creado: $OutputPath"
    }
}
#endregion

#region ── Conexión ───────────────────────────────────────────────────────────
Ensure-Output

Write-Log "Conectando al Admin Center: $TenantAdminUrl"
Connect-PnPOnline -Url $TenantAdminUrl `
    -ClientId $ClientId `
    -Thumbprint $Thumbprint `
    -Tenant $TenantId
Write-Log "Conexión establecida."
#endregion

#region ── 1. Inventario de sitios ───────────────────────────────────────────
Write-Log "Obteniendo listado de sitios..."

$allSites = Get-PnPTenantSite -IncludeOneDriveSites:$false -Detailed |
    Select-Object Url, Title, Template, StorageUsageCurrent, StorageMaximumLevel,
                  SharingCapability, LockState, LastContentModifiedDate,
                  Owner, SiteDefinedSharingCapability, GroupId, HubSiteId,
                  ConditionalAccessPolicy, SensitivityLabel, RelatedGroupId

$allSites | Export-Csv "$OutputPath\01_SiteInventory.csv" -NoTypeInformation -Encoding UTF8
Write-Log "Sitios exportados: $($allSites.Count)"
#endregion

#region ── 2. Sitios grandes (> 25 GB) ───────────────────────────────────────
$largeSites = $allSites | Where-Object { $_.StorageUsageCurrent -gt 25600 }
$largeSites | Export-Csv "$OutputPath\02_LargeSites_Over25GB.csv" -NoTypeInformation -Encoding UTF8
Write-Log "Sitios grandes (>25 GB): $($largeSites.Count)"
#endregion

#region ── 3. Inventario detallado por sitio ─────────────────────────────────
Write-Log "Iniciando análisis detallado por sitio..."

$libraryReport   = [System.Collections.Generic.List[PSObject]]::new()
$permissionReport= [System.Collections.Generic.List[PSObject]]::new()
$hubReport       = [System.Collections.Generic.List[PSObject]]::new()

foreach ($site in $allSites) {
    Write-Log "Procesando sitio: $($site.Url)"
    try {
        Connect-PnPOnline -Url $site.Url `
            -ClientId $ClientId `
            -Thumbprint $Thumbprint `
            -Tenant $TenantId

        # ── 3a. Bibliotecas y listas ──────────────────────────────────────
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

        # ── 3b. Permisos únicos en el sitio ──────────────────────────────
        $web = Get-PnPWeb -Includes HasUniqueRoleAssignments, RoleAssignments
        if ($web.HasUniqueRoleAssignments) {
            $roleAssignments = Get-PnPWebPermission
            foreach ($ra in $roleAssignments) {
                $permissionReport.Add([PSCustomObject]@{
                    SiteUrl     = $site.Url
                    Principal   = $ra.PrincipalName
                    PrincipalType = $ra.PrincipalType
                    Roles       = ($ra.Roles -join '; ')
                    IsInherited = $ra.IsInherited
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
        Write-Log "Error en sitio $($site.Url): $_" -Level WARN
    }
}

$libraryReport    | Export-Csv "$OutputPath\03_LibraryInventory.csv"    -NoTypeInformation -Encoding UTF8
$permissionReport | Export-Csv "$OutputPath\04_UniquePermissions.csv"   -NoTypeInformation -Encoding UTF8
$hubReport        | Export-Csv "$OutputPath\05_HubSiteMembers.csv"      -NoTypeInformation -Encoding UTF8

Write-Log "Bibliotecas analizadas: $($libraryReport.Count)"
Write-Log "Asignaciones de permiso únicas: $($permissionReport.Count)"
#endregion

#region ── 4. Resumen ejecutivo ──────────────────────────────────────────────
$summary = [PSCustomObject]@{
    FechaAnalisis         = Get-Date -Format 'yyyy-MM-dd HH:mm'
    TotalSitios           = $allSites.Count
    SitiosGrandes         = $largeSites.Count
    TotalBibliotecas      = $libraryReport.Count
    TotalPermisosUnicos   = $permissionReport.Count
    SitiosEnHub           = $hubReport.Count
    StorageTotalGB        = [math]::Round(($allSites | Measure-Object -Property StorageUsageCurrent -Sum).Sum / 1024, 2)
}

$summary | ConvertTo-Json | Out-File "$OutputPath\00_ExecutiveSummary.json" -Encoding UTF8
Write-Log "=== ASSESSMENT COMPLETADO ===" 
Write-Log "Resultados en: $OutputPath"

Disconnect-PnPOnline
#endregion
