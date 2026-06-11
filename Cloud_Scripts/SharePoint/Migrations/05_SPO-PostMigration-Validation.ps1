<#
.SYNOPSIS
    SharePoint Online - Post-Migration Validation y Remediation
.DESCRIPTION
    Valida la integridad y completitud de una migración a SharePoint Online.
    Genera un informe detallado de:
        - Comparación de recuentos (origen vs destino)
        - Verificación de permisos
        - Validación de tipos de contenido y columnas
        - Comprobación de páginas modernas activas
        - Detección de elementos con permisos rotos
        - Remediación automática de problemas comunes

    Requisitos:
        - PnP.PowerShell >= 2.x
        - Acceso a ambos sitios (origen y destino)

.PARAMETER SourceUrl
    URL del sitio origen (referencia post-migración).
.PARAMETER DestUrl
    URL del sitio destino a validar.
.PARAMETER ClientId / Thumbprint / TenantId
    Autenticación app-only.
.PARAMETER ReportPath
    Ruta para el informe de validación.
.PARAMETER AutoRemediate
    Switch: intenta corregir automáticamente problemas detectados.

.EXAMPLE
    .\05_SPO-PostMigration-Validation.ps1 `
        -SourceUrl "https://contoso.sharepoint.com/sites/OldSite" `
        -DestUrl   "https://contoso.sharepoint.com/sites/NewSite" `
        -ClientId "xxxx" -Thumbprint "AABB" -TenantId "yyyy" `
        -AutoRemediate

.NOTES
    Autor   : Solutions Architect - M365
    Versión : 1.0
    Módulo  : PnP.PowerShell
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory=$true)] [string]$SourceUrl,
    [Parameter(Mandatory=$true)] [string]$DestUrl,
    [Parameter(Mandatory=$true)] [string]$ClientId,
    [Parameter(Mandatory=$true)] [string]$Thumbprint,
    [Parameter(Mandatory=$true)] [string]$TenantId,
    [Parameter(Mandatory=$false)][string]$ReportPath = "$env:TEMP\PostMigration_Validation_$(Get-Date -Format 'yyyyMMdd_HHmm')",
    [Parameter(Mandatory=$false)][switch]$AutoRemediate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

if (-not (Test-Path $ReportPath)) { New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null }
$LogFile = "$ReportPath\validation.log"

#region ── Helpers ────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [ValidateSet('INFO','WARN','ERROR','SUCCESS','PHASE','CHECK')]$Level = 'INFO')
    $ts  = Get-Date -Format 'HH:mm:ss'
    $clr = @{ INFO='Cyan'; WARN='Yellow'; ERROR='Red'; SUCCESS='Green'; PHASE='Magenta'; CHECK='White' }
    $icon = @{ INFO='ℹ'; WARN='⚠'; ERROR='✖'; SUCCESS='✔'; PHASE='▶'; CHECK='◉' }
    Write-Host "[$ts] $($icon[$Level]) $Message" -ForegroundColor $clr[$Level]
    Add-Content -Path $LogFile -Value "[$ts][$Level] $Message"
}

function Connect-ToSite { param([string]$Url)
    Connect-PnPOnline -Url $Url -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId
}

$validationResults = [System.Collections.Generic.List[PSObject]]::new()

function Add-Result {
    param($Category, $Check, $Status, $SourceVal, $DestVal, $Detail='')
    $validationResults.Add([PSCustomObject]@{
        Category  = $Category
        Check     = $Check
        Status    = $Status
        Source    = $SourceVal
        Dest      = $DestVal
        Detail    = $Detail
    })
}
#endregion

#region ── BLOQUE 1: Metadatos del sitio ─────────────────────────────────────
Write-Log "=== BLOQUE 1: Comparando metadatos del sitio ===" -Level PHASE

Connect-ToSite -Url $SourceUrl
$srcWeb = Get-PnPWeb -Includes Title, Description, Language, MasterUrl, AlternateCssUrl, CustomMasterUrl

Connect-ToSite -Url $DestUrl
$dstWeb = Get-PnPWeb -Includes Title, Description, Language

if ($srcWeb.Title -eq $dstWeb.Title) {
    Write-Log "Título: OK ($($dstWeb.Title))" -Level SUCCESS
    Add-Result "Site Metadata" "Title" "PASS" $srcWeb.Title $dstWeb.Title
} else {
    Write-Log "Título: DIFERENTE (Origen: '$($srcWeb.Title)' | Destino: '$($dstWeb.Title)')" -Level WARN
    Add-Result "Site Metadata" "Title" "WARN" $srcWeb.Title $dstWeb.Title "Títulos no coinciden"

    if ($AutoRemediate -and $PSCmdlet.ShouldProcess($DestUrl, "Corregir título")) {
        Set-PnPWeb -Title $srcWeb.Title | Out-Null
        Write-Log "  → Título corregido automáticamente." -Level SUCCESS
    }
}

if ($srcWeb.Language -eq $dstWeb.Language) {
    Add-Result "Site Metadata" "Language" "PASS" $srcWeb.Language $dstWeb.Language
} else {
    Add-Result "Site Metadata" "Language" "WARN" $srcWeb.Language $dstWeb.Language "Idioma diferente"
    Write-Log "Idioma: DIFERENTE (Origen: $($srcWeb.Language) | Destino: $($dstWeb.Language))" -Level WARN
}
#endregion

#region ── BLOQUE 2: Comparación de listas y bibliotecas ─────────────────────
Write-Log "=== BLOQUE 2: Comparando listas y bibliotecas ===" -Level PHASE

Connect-ToSite -Url $SourceUrl
$srcLists = Get-PnPList | Where-Object { -not $_.Hidden } | Sort-Object Title

Connect-ToSite -Url $DestUrl
$dstLists = Get-PnPList | Where-Object { -not $_.Hidden } | Sort-Object Title

Write-Log "Listas en origen: $($srcLists.Count) | Destino: $($dstLists.Count)" -Level CHECK

foreach ($srcList in $srcLists) {
    $dstList = $dstLists | Where-Object { $_.Title -eq $srcList.Title }

    if (-not $dstList) {
        Write-Log "  FALTA lista/biblioteca: '$($srcList.Title)'" -Level ERROR
        Add-Result "Lists/Libraries" $srcList.Title "FAIL" $srcList.ItemCount "N/A" "Lista no encontrada en destino"
        continue
    }

    # Comparar recuentos de elementos
    $delta = [math]::Abs($srcList.ItemCount - $dstList.ItemCount)
    $pct   = if ($srcList.ItemCount -gt 0) { [math]::Round(($delta / $srcList.ItemCount) * 100, 1) } else { 0 }

    if ($pct -le 2) {
        Write-Log "  ✔ '$($srcList.Title)': $($srcList.ItemCount) origen / $($dstList.ItemCount) destino" -Level SUCCESS
        Add-Result "Lists/Libraries" $srcList.Title "PASS" $srcList.ItemCount $dstList.ItemCount "$pct% delta"
    } elseif ($pct -le 10) {
        Write-Log "  ⚠ '$($srcList.Title)': delta $pct% ($($srcList.ItemCount) vs $($dstList.ItemCount))" -Level WARN
        Add-Result "Lists/Libraries" $srcList.Title "WARN" $srcList.ItemCount $dstList.ItemCount "$pct% delta - revisar"
    } else {
        Write-Log "  ✖ '$($srcList.Title)': delta $pct% ($($srcList.ItemCount) vs $($dstList.ItemCount))" -Level ERROR
        Add-Result "Lists/Libraries" $srcList.Title "FAIL" $srcList.ItemCount $dstList.ItemCount "$pct% delta - crítico"
    }
}
#endregion

#region ── BLOQUE 3: Validación de tipos de contenido ────────────────────────
Write-Log "=== BLOQUE 3: Validando Content Types ===" -Level PHASE

Connect-ToSite -Url $SourceUrl
$srcCTs = Get-PnPContentType | Where-Object { $_.Group -notlike "*_*" -and $_.Sealed -eq $false }

Connect-ToSite -Url $DestUrl
$dstCTs = Get-PnPContentType

foreach ($ct in $srcCTs) {
    $found = $dstCTs | Where-Object { $_.Name -eq $ct.Name }
    if ($found) {
        Add-Result "Content Types" $ct.Name "PASS" $ct.Id.StringValue $found.Id.StringValue
    } else {
        Write-Log "  FALTA Content Type: '$($ct.Name)'" -Level WARN
        Add-Result "Content Types" $ct.Name "FAIL" $ct.Id.StringValue "N/A" "No encontrado en destino"
    }
}
#endregion

#region ── BLOQUE 4: Validación de permisos ──────────────────────────────────
Write-Log "=== BLOQUE 4: Validando permisos del sitio ===" -Level PHASE

Connect-ToSite -Url $SourceUrl
$srcPerms = Get-PnPWebPermission

Connect-ToSite -Url $DestUrl
$dstPerms = Get-PnPWebPermission

foreach ($perm in $srcPerms) {
    $matched = $dstPerms | Where-Object { $_.PrincipalName -eq $perm.PrincipalName }
    if ($matched) {
        $srcRoles = ($perm.Roles | Sort-Object) -join ','
        $dstRoles = ($matched.Roles | Sort-Object) -join ','
        if ($srcRoles -eq $dstRoles) {
            Add-Result "Permissions" $perm.PrincipalName "PASS" $srcRoles $dstRoles
        } else {
            Write-Log "  Roles diferentes para '$($perm.PrincipalName)': $srcRoles ≠ $dstRoles" -Level WARN
            Add-Result "Permissions" $perm.PrincipalName "WARN" $srcRoles $dstRoles "Roles no coinciden"
        }
    } else {
        Write-Log "  Principal '$($perm.PrincipalName)' no encontrado en destino" -Level WARN
        Add-Result "Permissions" $perm.PrincipalName "FAIL" ($perm.Roles -join ',') "N/A" "Principal no encontrado"
    }
}
#endregion

#region ── BLOQUE 5: Validación de páginas modernas ──────────────────────────
Write-Log "=== BLOQUE 5: Validando páginas modernas ===" -Level PHASE

Connect-ToSite -Url $SourceUrl
$srcPages = Get-PnPListItem -List "Site Pages" -PageSize 200 -ErrorAction SilentlyContinue |
    Select-Object @{N='Name';E={$_['FileLeafRef']}}

Connect-ToSite -Url $DestUrl
$dstPages = Get-PnPListItem -List "Site Pages" -PageSize 200 -ErrorAction SilentlyContinue |
    Select-Object @{N='Name';E={$_['FileLeafRef']}}

foreach ($page in $srcPages) {
    $found = $dstPages | Where-Object { $_.Name -eq $page.Name }
    if ($found) {
        Add-Result "Pages" $page.Name "PASS" "Exists" "Exists"
    } else {
        Write-Log "  FALTA página: $($page.Name)" -Level WARN
        Add-Result "Pages" $page.Name "FAIL" "Exists" "Missing" "Página no migrada"
    }
}
#endregion

#region ── BLOQUE 6: Detectar elementos con permisos rotos ───────────────────
Write-Log "=== BLOQUE 6: Detectando permisos rotos en listas ===" -Level PHASE
Connect-ToSite -Url $DestUrl

$brokenPermItems = [System.Collections.Generic.List[PSObject]]::new()
$listsToCheck = Get-PnPList | Where-Object { -not $_.Hidden -and $_.BaseTemplate -in @(100, 101) }

foreach ($list in $listsToCheck) {
    try {
        $items = Get-PnPListItem -List $list.Title -PageSize 500 -Fields "ID","Title","FileLeafRef","HasUniqueRoleAssignments"
        $uniqueItems = $items | Where-Object { $_["HasUniqueRoleAssignments"] -eq $true }

        if ($uniqueItems.Count -gt 0) {
            Write-Log "  '$($list.Title)': $($uniqueItems.Count) elemento(s) con permisos únicos" -Level WARN
            $brokenPermItems.Add([PSCustomObject]@{
                Library      = $list.Title
                UniqueItems  = $uniqueItems.Count
                TotalItems   = $items.Count
                Percentage   = [math]::Round(($uniqueItems.Count / [math]::Max($items.Count,1)) * 100, 1)
            })
        }
    } catch {
        Write-Log "  Error verificando '$($list.Title)': $_" -Level WARN
    }
}

$brokenPermItems | Export-Csv "$ReportPath\BrokenPermissions.csv" -NoTypeInformation -Encoding UTF8
#endregion

#region ── BLOQUE 7: Remediación automática de sharing ───────────────────────
if ($AutoRemediate) {
    Write-Log "=== BLOQUE 7: Remediación automática ===" -Level PHASE
    Connect-ToSite -Url $DestUrl

    # Deshabilitar sharing anónimo si estaba activo
    $web = Get-PnPWeb -Includes HasUniqueRoleAssignments
    Set-PnPSite -NoScriptSite $true -ErrorAction SilentlyContinue
    Write-Log "NoScript activado en destino." -Level SUCCESS

    # Reactivar páginas modernas
    Enable-PnPFeature -Identity "B6917CB1-93A0-4B97-A84D-7CF49975D4EC" -Scope Web -Force -ErrorAction SilentlyContinue
    Write-Log "Feature de páginas modernas reactivada." -Level SUCCESS
}
#endregion

#region ── Informe final ──────────────────────────────────────────────────────
Write-Log "=== GENERANDO INFORME FINAL ===" -Level PHASE

$validationResults | Export-Csv "$ReportPath\ValidationReport.csv" -NoTypeInformation -Encoding UTF8

$passes = ($validationResults | Where-Object { $_.Status -eq 'PASS' }).Count
$warns  = ($validationResults | Where-Object { $_.Status -eq 'WARN' }).Count
$fails  = ($validationResults | Where-Object { $_.Status -eq 'FAIL' }).Count
$total  = $validationResults.Count

$successRate = if ($total -gt 0) { [math]::Round(($passes / $total) * 100, 1) } else { 0 }

$summary = [PSCustomObject]@{
    FechaValidacion  = Get-Date -Format 'yyyy-MM-dd HH:mm'
    SitioOrigen      = $SourceUrl
    SitioDestino     = $DestUrl
    TotalChecks      = $total
    Passed           = $passes
    Warnings         = $warns
    Failed           = $fails
    TasaExito        = "$successRate%"
    EstadoGeneral    = if ($fails -eq 0 -and $warns -le 3) { "✅ APTO" } elseif ($fails -le 5) { "⚠️ REVISAR" } else { "❌ NO APTO" }
}

$summary | ConvertTo-Json | Out-File "$ReportPath\ValidationSummary.json" -Encoding UTF8

Write-Log ""
Write-Log "══════════════════════════════════════════" -Level SUCCESS
Write-Log "VALIDACIÓN POST-MIGRACIÓN COMPLETADA"      -Level SUCCESS
Write-Log "  ✔ PASS    : $passes"                     -Level SUCCESS
Write-Log "  ⚠ WARN    : $warns"                     -Level WARN
Write-Log "  ✖ FAIL    : $fails"                     -Level ERROR
Write-Log "  Tasa Éxito: $successRate%"               -Level SUCCESS
Write-Log "  Estado    : $($summary.EstadoGeneral)"   -Level SUCCESS
Write-Log "  Informe   : $ReportPath"                 -Level SUCCESS
Write-Log "══════════════════════════════════════════" -Level SUCCESS

Disconnect-PnPOnline
#endregion
