<#
.SYNOPSIS
    SharePoint Online - Gestión Masiva de Permisos en Migración
.DESCRIPTION
    Administra, audita y remedia permisos de forma masiva durante o post migración.
    Incluye:
        - Auditoría completa de permisos a nivel sitio/lista/item
        - Ruptura y herencia de permisos en lote
        - Eliminación de usuarios externos obsoletos
        - Reemplazo de grupos de seguridad (útil en T2T)
        - Exportación de matriz de permisos en Excel-compatible CSV

    Requisitos:
        - PnP.PowerShell >= 2.x
        - Permisos de Site Owner o superior

.PARAMETER SiteUrl
    URL del sitio a gestionar.
.PARAMETER ClientId / Thumbprint / TenantId
    Autenticación app-only.
.PARAMETER Mode
    Modo de operación:
        Audit       - Solo audita, sin cambios
        BreakInheritance  - Rompe herencia en listas seleccionadas
        RestoreInheritance - Restaura herencia
        RemoveExternal - Elimina usuarios externos del sitio
        ReplaceGroup  - Reemplaza un grupo por otro
.PARAMETER TargetLists
    Array de nombres de listas para operar (vacío = todas).
.PARAMETER OldGroupName / NewGroupName
    Para modo ReplaceGroup.
.PARAMETER OutputPath
    Carpeta de salida para informes.

.EXAMPLE
    # Auditoría completa
    .\06_SPO-Permissions-Management.ps1 `
        -SiteUrl "https://contoso.sharepoint.com/sites/HR" `
        -ClientId "xxxx" -Thumbprint "AABB" -TenantId "yyyy" `
        -Mode Audit

    # Eliminar externos
    .\06_SPO-Permissions-Management.ps1 `
        -SiteUrl "https://contoso.sharepoint.com/sites/HR" `
        -ClientId "xxxx" -Thumbprint "AABB" -TenantId "yyyy" `
        -Mode RemoveExternal

.NOTES
    Autor   : Solutions Architect - M365
    Versión : 1.0
    Módulo  : PnP.PowerShell
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory=$true)]
    [string]$SiteUrl,

    [Parameter(Mandatory=$true)] [string]$ClientId,
    [Parameter(Mandatory=$true)] [string]$Thumbprint,
    [Parameter(Mandatory=$true)] [string]$TenantId,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Audit","BreakInheritance","RestoreInheritance","RemoveExternal","ReplaceGroup")]
    [string]$Mode,

    [Parameter(Mandatory=$false)][string[]]$TargetLists = @(),
    [Parameter(Mandatory=$false)][string]$OldGroupName,
    [Parameter(Mandatory=$false)][string]$NewGroupName,
    [Parameter(Mandatory=$false)][string]$OutputPath = "$env:TEMP\SPO_Permissions_$(Get-Date -Format 'yyyyMMdd_HHmm')"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"
if (-not (Test-Path $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
$LogFile = "$OutputPath\permissions.log"

#region ── Helpers ────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message, [ValidateSet('INFO','WARN','ERROR','SUCCESS','PHASE')]$Level = 'INFO')
    $ts  = Get-Date -Format 'HH:mm:ss'
    $clr = @{ INFO='Cyan'; WARN='Yellow'; ERROR='Red'; SUCCESS='Green'; PHASE='Magenta' }
    Write-Host "[$ts][$Level] $Message" -ForegroundColor $clr[$Level]
    Add-Content -Path $LogFile -Value "[$ts][$Level] $Message"
}

function Connect-ToSite {
    Connect-PnPOnline -Url $SiteUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId
}
#endregion

Connect-ToSite
Write-Log "Conectado a: $SiteUrl | Modo: $Mode" -Level PHASE

$lists = if ($TargetLists.Count -gt 0) {
    Get-PnPList | Where-Object { $_.Title -in $TargetLists -and -not $_.Hidden }
} else {
    Get-PnPList | Where-Object { -not $_.Hidden }
}

#region ── MODO: Audit ────────────────────────────────────────────────────────
if ($Mode -eq "Audit") {
    Write-Log "=== AUDITORÍA DE PERMISOS ===" -Level PHASE
    $permMatrix = [System.Collections.Generic.List[PSObject]]::new()

    # Nivel Sitio
    $sitePerms = Get-PnPWebPermission
    foreach ($p in $sitePerms) {
        $permMatrix.Add([PSCustomObject]@{
            Nivel       = "Sitio"
            Objeto      = $SiteUrl
            Principal   = $p.PrincipalName
            Tipo        = $p.PrincipalType
            Roles       = ($p.Roles -join '; ')
            Heredado    = $p.IsInherited
        })
    }

    # Nivel Lista/Biblioteca
    foreach ($list in $lists) {
        $listObj = Get-PnPList -Identity $list.Title -Includes HasUniqueRoleAssignments
        if ($listObj.HasUniqueRoleAssignments) {
            $listPerms = Get-PnPListPermissions -Identity $list.Title -ErrorAction SilentlyContinue
            foreach ($lp in $listPerms) {
                $permMatrix.Add([PSCustomObject]@{
                    Nivel     = "Lista/Biblioteca"
                    Objeto    = $list.Title
                    Principal = $lp.PrincipalName
                    Tipo      = $lp.PrincipalType
                    Roles     = ($lp.Roles -join '; ')
                    Heredado  = $false
                })
            }
        }

        # Nivel Elemento (solo para listas pequeñas)
        if ($list.ItemCount -le 1000 -and $list.BaseTemplate -eq 100) {
            $items = Get-PnPListItem -List $list.Title -PageSize 500
            foreach ($item in $items) {
                $itemObj = Get-PnPListItem -List $list.Title -Id $item.Id -Includes "HasUniqueRoleAssignments"
                if ($itemObj.HasUniqueRoleAssignments) {
                    $itemPerms = Get-PnPListItemPermission -List $list.Title -Identity $item.Id -ErrorAction SilentlyContinue
                    foreach ($ip in $itemPerms) {
                        $permMatrix.Add([PSCustomObject]@{
                            Nivel     = "Elemento"
                            Objeto    = "$($list.Title) / ID:$($item.Id)"
                            Principal = $ip.PrincipalName
                            Tipo      = $ip.PrincipalType
                            Roles     = ($ip.Roles -join '; ')
                            Heredado  = $false
                        })
                    }
                }
            }
        }
    }

    $permMatrix | Export-Csv "$OutputPath\PermissionMatrix.csv" -NoTypeInformation -Encoding UTF8
    Write-Log "Matriz de permisos exportada: $($permMatrix.Count) entradas." -Level SUCCESS
    Write-Log "Archivo: $OutputPath\PermissionMatrix.csv" -Level SUCCESS
}
#endregion

#region ── MODO: BreakInheritance ────────────────────────────────────────────
if ($Mode -eq "BreakInheritance") {
    Write-Log "=== ROMPIENDO HERENCIA EN LISTAS ===" -Level PHASE
    foreach ($list in $lists) {
        if ($PSCmdlet.ShouldProcess($list.Title, "Romper herencia de permisos")) {
            try {
                Set-PnPList -Identity $list.Title -BreakRoleInheritance -CopyRoleAssignments | Out-Null
                Write-Log "Herencia rota en: '$($list.Title)'" -Level SUCCESS
            } catch {
                Write-Log "Error en '$($list.Title)': $_" -Level ERROR
            }
        }
    }
}
#endregion

#region ── MODO: RestoreInheritance ──────────────────────────────────────────
if ($Mode -eq "RestoreInheritance") {
    Write-Log "=== RESTAURANDO HERENCIA EN LISTAS ===" -Level PHASE
    foreach ($list in $lists) {
        if ($PSCmdlet.ShouldProcess($list.Title, "Restaurar herencia de permisos")) {
            try {
                Set-PnPList -Identity $list.Title -ResetRoleInheritance | Out-Null
                Write-Log "Herencia restaurada en: '$($list.Title)'" -Level SUCCESS
            } catch {
                Write-Log "Error en '$($list.Title)': $_" -Level ERROR
            }
        }
    }
}
#endregion

#region ── MODO: RemoveExternal ──────────────────────────────────────────────
if ($Mode -eq "RemoveExternal") {
    Write-Log "=== ELIMINANDO USUARIOS EXTERNOS ===" -Level PHASE
    $externalReport = [System.Collections.Generic.List[PSObject]]::new()

    # Obtener todos los usuarios del sitio
    $siteUsers = Get-PnPUser | Where-Object {
        ($_.LoginName -like "*#ext#*" -or $_.Email -like "*#EXT#*") -and
        $_.PrincipalType -eq "User"
    }

    Write-Log "Usuarios externos encontrados: $($siteUsers.Count)"

    foreach ($user in $siteUsers) {
        $externalReport.Add([PSCustomObject]@{
            DisplayName = $user.Title
            Email       = $user.Email
            LoginName   = $user.LoginName
            Action      = "Pendiente eliminación"
        })

        if ($PSCmdlet.ShouldProcess($user.Email, "Eliminar usuario externo del sitio")) {
            try {
                Remove-PnPUser -Identity $user.LoginName -Force -ErrorAction Stop
                Write-Log "  Eliminado: $($user.Email)" -Level SUCCESS
                $externalReport[-1].Action = "Eliminado"
            } catch {
                Write-Log "  Error eliminando '$($user.Email)': $_" -Level WARN
                $externalReport[-1].Action = "Error: $_"
            }
        }
    }

    $externalReport | Export-Csv "$OutputPath\RemovedExternals.csv" -NoTypeInformation -Encoding UTF8
    Write-Log "Informe: $OutputPath\RemovedExternals.csv" -Level SUCCESS
}
#endregion

#region ── MODO: ReplaceGroup ────────────────────────────────────────────────
if ($Mode -eq "ReplaceGroup") {
    if (-not $OldGroupName -or -not $NewGroupName) {
        Write-Log "Se requieren -OldGroupName y -NewGroupName para ReplaceGroup." -Level ERROR
        exit 1
    }
    Write-Log "=== REEMPLAZANDO GRUPO: '$OldGroupName' → '$NewGroupName' ===" -Level PHASE

    # Buscar el grupo origen y sus permisos actuales en el sitio
    $oldGroup = Get-PnPGroup -Identity $OldGroupName -ErrorAction SilentlyContinue
    $newGroup = Get-PnPGroup -Identity $NewGroupName -ErrorAction SilentlyContinue

    if (-not $oldGroup) { Write-Log "Grupo origen '$OldGroupName' no encontrado." -Level ERROR; exit 1 }
    if (-not $newGroup) {
        Write-Log "Grupo destino '$NewGroupName' no existe. Creando..." -Level WARN
        $newGroup = New-PnPGroup -Title $NewGroupName
    }

    # Obtener roles actuales del grupo origen en el sitio
    $web = Get-PnPWeb -Includes RoleAssignments
    foreach ($ra in $web.RoleAssignments) {
        if ($ra.Member.LoginName -like "*$OldGroupName*") {
            $roleDefinitions = $ra.RoleDefinitionBindings | Select-Object -ExpandProperty Name
            foreach ($role in $roleDefinitions) {
                if ($PSCmdlet.ShouldProcess($SiteUrl, "Asignar rol '$role' a '$NewGroupName'")) {
                    Set-PnPWebPermission -Group $NewGroupName -AddRole $role | Out-Null
                    Write-Log "  Rol '$role' asignado a '$NewGroupName'" -Level SUCCESS
                }
            }
        }
    }

    # Eliminar el grupo antiguo del sitio (no del tenant)
    if ($PSCmdlet.ShouldProcess($SiteUrl, "Remover '$OldGroupName' del sitio")) {
        Set-PnPWebPermission -Group $OldGroupName -RemoveRole "Full Control" -ErrorAction SilentlyContinue
        Set-PnPWebPermission -Group $OldGroupName -RemoveRole "Edit"         -ErrorAction SilentlyContinue
        Set-PnPWebPermission -Group $OldGroupName -RemoveRole "Read"         -ErrorAction SilentlyContinue
        Write-Log "  Permisos de '$OldGroupName' eliminados del sitio." -Level SUCCESS
    }
}
#endregion

Write-Log "=== OPERACIÓN COMPLETADA ===" -Level SUCCESS
Write-Log "Log: $LogFile" -Level SUCCESS
Disconnect-PnPOnline
