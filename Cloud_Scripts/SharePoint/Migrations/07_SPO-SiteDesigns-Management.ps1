<#
.SYNOPSIS
    SharePoint Online - Creación y Despliegue Masivo de Site Designs con PnP
.DESCRIPTION
    Automatiza la creación, gestión y aplicación de Site Designs y Site Scripts
    en M365. Herramienta clave para arquitectos que necesitan estandarizar la
    estructura de sitios en proyectos de migración o adopción.

    Incluye:
        - Creación de Site Scripts desde JSON o plantillas PnP
        - Despliegue de Site Designs personalizados
        - Aplicación masiva de Site Designs a sitios existentes
        - Exportación de Site Scripts activos
        - Gestión del catálogo de Site Designs del tenant

    Requisitos:
        - PnP.PowerShell >= 2.x
        - Rol: SharePoint Administrator

.PARAMETER TenantAdminUrl
    URL del Admin Center.
.PARAMETER ClientId / Thumbprint / TenantId
    Autenticación app-only.
.PARAMETER Mode
    Acción a ejecutar:
        Create        - Crea Site Script + Site Design nuevos
        ApplyToSites  - Aplica un Site Design a múltiples sitios
        ExportAll     - Exporta todos los Site Scripts y Designs al disco
        Cleanup       - Elimina Site Designs y Scripts obsoletos
.PARAMETER SiteDesignName
    Nombre del Site Design a crear o aplicar.
.PARAMETER SiteScriptJsonPath
    Ruta al JSON del Site Script para creación.
.PARAMETER TargetSiteUrls
    Array de URLs a las que aplicar el Site Design.
.PARAMETER WebTemplate
    Plantilla web destino: 64 (Team Site), 68 (Communication Site).
.PARAMETER OutputPath
    Carpeta de exportación.

.EXAMPLE
    # Crear nuevo Site Design
    .\07_SPO-SiteDesigns-Management.ps1 `
        -TenantAdminUrl "https://contoso-admin.sharepoint.com" `
        -ClientId "xxxx" -Thumbprint "AABB" -TenantId "yyyy" `
        -Mode Create -SiteDesignName "Departmental Site Template" `
        -SiteScriptJsonPath "C:\SiteScript.json" -WebTemplate "64"

    # Aplicar a múltiples sitios
    .\07_SPO-SiteDesigns-Management.ps1 `
        -TenantAdminUrl "https://contoso-admin.sharepoint.com" `
        -ClientId "xxxx" -Thumbprint "AABB" -TenantId "yyyy" `
        -Mode ApplyToSites -SiteDesignName "Departmental Site Template" `
        -TargetSiteUrls @("https://contoso.sharepoint.com/sites/IT","https://contoso.sharepoint.com/sites/HR")

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

Write-Log "Conectando a Admin Center: $TenantAdminUrl" -Level PHASE
Connect-PnPOnline -Url $TenantAdminUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId

#region ── MODO: Create ───────────────────────────────────────────────────────
if ($Mode -eq "Create") {
    Write-Log "=== CREANDO SITE SCRIPT + SITE DESIGN ===" -Level PHASE

    if (-not $SiteScriptJsonPath -or -not (Test-Path $SiteScriptJsonPath)) {
        # Si no se proporciona JSON, usar una plantilla por defecto
        Write-Log "No se especificó SiteScriptJsonPath. Usando plantilla por defecto." -Level WARN

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
                    url      = "/sites/migration-tracker"
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
        Write-Log "Plantilla por defecto guardada en: $SiteScriptJsonPath" -Level INFO
    }

    $scriptJson = Get-Content $SiteScriptJsonPath -Raw

    try {
        if ($PSCmdlet.ShouldProcess($SiteDesignName, "Crear Site Script")) {
            $siteScript = Add-PnPSiteScript -Title "$SiteDesignName Script" -Content $scriptJson
            Write-Log "Site Script creado: ID=$($siteScript.Id)" -Level SUCCESS

            $siteDesign = Add-PnPSiteDesign `
                -Title $SiteDesignName `
                -SiteScripts @($siteScript.Id) `
                -WebTemplate $WebTemplate `
                -Description "Site Design creado por script de migración M365 - $(Get-Date -Format 'yyyy-MM-dd')" `
                -ThumbnailUrl ""

            Write-Log "Site Design creado: ID=$($siteDesign.Id)" -Level SUCCESS
            Write-Log "Detalles:" -Level INFO
            Write-Log "  Nombre     : $($siteDesign.Title)"
            Write-Log "  ID         : $($siteDesign.Id)"
            Write-Log "  Template   : $($siteDesign.WebTemplate)"
            Write-Log "  ScriptIDs  : $($siteDesign.SiteScriptIds -join ', ')"

            # Exportar info del design creado
            [PSCustomObject]@{
                DesignName = $siteDesign.Title
                DesignId   = $siteDesign.Id
                ScriptId   = $siteScript.Id
                Template   = $WebTemplate
                CreatedAt  = Get-Date -Format 'yyyy-MM-dd HH:mm'
            } | ConvertTo-Json | Out-File "$OutputPath\CreatedDesign_$($siteDesign.Id).json" -Encoding UTF8
        }
    } catch {
        Write-Log "Error creando Site Script/Design: $_" -Level ERROR
    }
}
#endregion

#region ── MODO: ApplyToSites ────────────────────────────────────────────────
if ($Mode -eq "ApplyToSites") {
    Write-Log "=== APLICANDO SITE DESIGN A MÚLTIPLES SITIOS ===" -Level PHASE

    if (-not $SiteDesignName) { Write-Log "-SiteDesignName requerido." -Level ERROR; exit 1 }
    if ($TargetSiteUrls.Count -eq 0) { Write-Log "-TargetSiteUrls requerido." -Level ERROR; exit 1 }

    $design = Get-PnPSiteDesign | Where-Object { $_.Title -eq $SiteDesignName }
    if (-not $design) {
        Write-Log "Site Design '$SiteDesignName' no encontrado en el tenant." -Level ERROR
        exit 1
    }

    Write-Log "Site Design ID: $($design.Id) | Sitios a procesar: $($TargetSiteUrls.Count)"
    $applyResults = [System.Collections.Generic.List[PSObject]]::new()

    foreach ($siteUrl in $TargetSiteUrls) {
        Write-Log "Aplicando a: $siteUrl"
        try {
            if ($PSCmdlet.ShouldProcess($siteUrl, "Aplicar Site Design '$SiteDesignName'")) {
                Connect-PnPOnline -Url $siteUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId
                $result = Invoke-PnPSiteDesign -Identity $design.Id
                Write-Log "  ✔ Aplicado correctamente." -Level SUCCESS
                $applyResults.Add([PSCustomObject]@{
                    SiteUrl    = $siteUrl
                    DesignId   = $design.Id
                    Status     = "SUCCESS"
                    AppliedAt  = Get-Date -Format 'yyyy-MM-dd HH:mm'
                })
                Connect-PnPOnline -Url $TenantAdminUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId
            }
        } catch {
            Write-Log "  ✖ Error en $siteUrl: $_" -Level ERROR
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
    Write-Log "Resultados: $OutputPath\ApplyResults.csv" -Level SUCCESS
}
#endregion

#region ── MODO: ExportAll ────────────────────────────────────────────────────
if ($Mode -eq "ExportAll") {
    Write-Log "=== EXPORTANDO TODOS LOS SITE DESIGNS Y SCRIPTS ===" -Level PHASE

    Connect-PnPOnline -Url $TenantAdminUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId

    $allDesigns = Get-PnPSiteDesign
    $allScripts = Get-PnPSiteScript

    Write-Log "Site Designs encontrados: $($allDesigns.Count)"
    Write-Log "Site Scripts encontrados: $($allScripts.Count)"

    # Exportar catálogo
    $allDesigns | Select-Object Title, Id, WebTemplate, Description, SiteScriptIds, IsDefault, PreviewImageUrl |
        Export-Csv "$OutputPath\Catalog_SiteDesigns.csv" -NoTypeInformation -Encoding UTF8

    # Exportar contenido de cada script
    $scriptsDir = "$OutputPath\SiteScripts"
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

    foreach ($script in $allScripts) {
        try {
            $scriptContent = Get-PnPSiteScript -Identity $script.Id
            $safeName = $script.Title -replace '[\\/:*?"<>|]', '_'
            $scriptContent.Content | Out-File "$scriptsDir\$safeName`_$($script.Id).json" -Encoding UTF8
            Write-Log "  Exportado: '$($script.Title)'" -Level SUCCESS
        } catch {
            Write-Log "  Error exportando '$($script.Title)': $_" -Level WARN
        }
    }

    Write-Log "Scripts exportados en: $scriptsDir" -Level SUCCESS
}
#endregion

#region ── MODO: Cleanup ──────────────────────────────────────────────────────
if ($Mode -eq "Cleanup") {
    Write-Log "=== LIMPIEZA DE SITE DESIGNS OBSOLETOS ===" -Level PHASE
    Connect-PnPOnline -Url $TenantAdminUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId

    $allDesigns = Get-PnPSiteDesign
    $allScripts = Get-PnPSiteScript

    # Identificar scripts huérfanos (sin design asociado)
    $referencedScriptIds = $allDesigns | ForEach-Object { $_.SiteScriptIds } | Where-Object { $_ } | Sort-Object -Unique
    $orphanScripts = $allScripts | Where-Object { $_.Id.Guid -notin $referencedScriptIds }

    Write-Log "Scripts huérfanos detectados: $($orphanScripts.Count)"
    foreach ($orphan in $orphanScripts) {
        Write-Log "  Huérfano: '$($orphan.Title)' (ID: $($orphan.Id))" -Level WARN
        if ($PSCmdlet.ShouldProcess($orphan.Title, "Eliminar Site Script huérfano")) {
            try {
                Remove-PnPSiteScript -Identity $orphan.Id -Force
                Write-Log "  ✔ Eliminado." -Level SUCCESS
            } catch {
                Write-Log "  ✖ Error: $_" -Level ERROR
            }
        }
    }
}
#endregion

Write-Log "=== OPERACIÓN '$Mode' COMPLETADA ===" -Level SUCCESS
Write-Log "Salida: $OutputPath" -Level SUCCESS
Disconnect-PnPOnline
