<#
.SYNOPSIS
    SPO-006 | SharePoint Online - Bulk Permissions Management during Migration.

.DESCRIPTION
    Manages, audits, and remediates permissions in bulk during or post migration.
    Includes:
        - Full permissions audit at site, list, and item levels.
        - Breaking and restoring role inheritance in bulk.
        - Removing obsolete external guest users from the site.
        - Replacing active security groups (useful during T2T migrations).
        - Exporting a permission matrix to an Excel-compatible CSV.

.PRODUCT
    SharePoint Online / PnP PowerShell

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - Module: PnP.PowerShell (>= 2.x)
    - Required permissions: Site Owner or higher

.PARAMETER SiteUrl
    URL of the site to manage.

.PARAMETER ClientId
    Client ID (AppID) of the Entra ID App Registration.

.PARAMETER Thumbprint
    Thumbprint of the certificate used for app-only authentication.

.PARAMETER TenantId
    Tenant ID (Directory ID GUID) of the Entra ID tenant.

.PARAMETER Mode
    Operation mode:
        Audit              - Audits permissions and exports report without making changes.
        BreakInheritance   - Breaks inheritance on target lists.
        RestoreInheritance - Restores inheritance on target lists.
        RemoveExternal     - Removes external guest users from the site.
        ReplaceGroup       - Replaces one security group with another.

.PARAMETER TargetLists
    Array of list/library titles to operate on (empty = all).

.PARAMETER OldGroupName
    Name of the old group to replace (used in ReplaceGroup mode).

.PARAMETER NewGroupName
    Name of the new group to apply (used in ReplaceGroup mode).

.PARAMETER OutputPath
    Local directory path where validation reports will be saved.

.EXAMPLE
    # Permissions Audit
    .\SPO-006_Permissions-Management.ps1 `
        -SiteUrl "https://contoso.sharepoint.com/sites/HR" `
        -ClientId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
        -Thumbprint "AABBCC..." `
        -TenantId "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" `
        -Mode Audit
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
Write-Log "Connected to: $SiteUrl | Mode: $Mode" -Level PHASE

$lists = if ($TargetLists.Count -gt 0) {
    Get-PnPList | Where-Object { $_.Title -in $TargetLists -and -not $_.Hidden }
} else {
    Get-PnPList | Where-Object { -not $_.Hidden }
}

#region ── Mode: Audit ────────────────────────────────────────────────────────
if ($Mode -eq "Audit") {
    Write-Log "=== PERMISSIONS AUDIT ===" -Level PHASE
    $permMatrix = [System.Collections.Generic.List[PSObject]]::new()

    # Site Level Permissions
    $sitePerms = Get-PnPWebPermission
    foreach ($p in $sitePerms) {
        $permMatrix.Add([PSCustomObject]@{
            Level       = "Site"
            Object      = $SiteUrl
            Principal   = $p.PrincipalName
            Type        = $p.PrincipalType
            Roles       = ($p.Roles -join '; ')
            Inherited   = $p.IsInherited
        })
    }

    # List/Library Level Permissions
    foreach ($list in $lists) {
        $listObj = Get-PnPList -Identity $list.Title -Includes HasUniqueRoleAssignments
        if ($listObj.HasUniqueRoleAssignments) {
            $listPerms = Get-PnPListPermissions -Identity $list.Title -ErrorAction SilentlyContinue
            foreach ($lp in $listPerms) {
                $permMatrix.Add([PSCustomObject]@{
                    Level     = "List/Library"
                    Object    = $list.Title
                    Principal = $lp.PrincipalName
                    Type      = $lp.PrincipalType
                    Roles     = ($lp.Roles -join '; ')
                    Inherited  = $false
                })
            }
        }

        # Item Level Permissions (only for smaller lists under 1000 items)
        if ($list.ItemCount -le 1000 -and $list.BaseTemplate -eq 100) {
            $items = Get-PnPListItem -List $list.Title -PageSize 500
            foreach ($item in $items) {
                $itemObj = Get-PnPListItem -List $list.Title -Id $item.Id -Includes "HasUniqueRoleAssignments"
                if ($itemObj.HasUniqueRoleAssignments) {
                    $itemPerms = Get-PnPListItemPermission -List $list.Title -Identity $item.Id -ErrorAction SilentlyContinue
                    foreach ($ip in $itemPerms) {
                        $permMatrix.Add([PSCustomObject]@{
                            Level     = "Item"
                            Object    = "$($list.Title) / ID:$($item.Id)"
                            Principal = $ip.PrincipalName
                            Type      = $ip.PrincipalType
                            Roles     = ($ip.Roles -join '; ')
                            Inherited  = $false
                        })
                    }
                }
            }
        }
    }

    $permMatrix | Export-Csv "$OutputPath\PermissionMatrix.csv" -NoTypeInformation -Encoding UTF8
    Write-Log "Permission matrix exported: $($permMatrix.Count) entries." -Level SUCCESS
    Write-Log "File: $OutputPath\PermissionMatrix.csv" -Level SUCCESS
}
#endregion

#region ── Mode: BreakInheritance ─────────────────────────────────────────────
if ($Mode -eq "BreakInheritance") {
    Write-Log "=== BREAKING ROLE INHERITANCE ON LISTS ===" -Level PHASE
    foreach ($list in $lists) {
        if ($PSCmdlet.ShouldProcess($list.Title, "Break permissions inheritance")) {
            try {
                Set-PnPList -Identity $list.Title -BreakRoleInheritance -CopyRoleAssignments | Out-Null
                Write-Log "Inheritance broken on: '$($list.Title)'" -Level SUCCESS
            } catch {
                Write-Log "Error on '$($list.Title)': $_" -Level ERROR
            }
        }
    }
}
#endregion

#region ── Mode: RestoreInheritance ───────────────────────────────────────────
if ($Mode -eq "RestoreInheritance") {
    Write-Log "=== RESTORING ROLE INHERITANCE ON LISTS ===" -Level PHASE
    foreach ($list in $lists) {
        if ($PSCmdlet.ShouldProcess($list.Title, "Restore permissions inheritance")) {
            try {
                Set-PnPList -Identity $list.Title -ResetRoleInheritance | Out-Null
                Write-Log "Inheritance restored on: '$($list.Title)'" -Level SUCCESS
            } catch {
                Write-Log "Error on '$($list.Title)': $_" -Level ERROR
            }
        }
    }
}
#endregion

#region ── Mode: RemoveExternal ───────────────────────────────────────────────
if ($Mode -eq "RemoveExternal") {
    Write-Log "=== REMOVING EXTERNAL GUEST USERS ===" -Level PHASE
    $externalReport = [System.Collections.Generic.List[PSObject]]::new()

    # Get all external users in the site
    $siteUsers = Get-PnPUser | Where-Object {
        ($_.LoginName -like "*#ext#*" -or $_.Email -like "*#EXT#*") -and
        $_.PrincipalType -eq "User"
    }

    Write-Log "External guest users found: $($siteUsers.Count)"

    foreach ($user in $siteUsers) {
        $externalReport.Add([PSCustomObject]@{
            DisplayName = $user.Title
            Email       = $user.Email
            LoginName   = $user.LoginName
            Action      = "Pending Removal"
        })

        if ($PSCmdlet.ShouldProcess($user.Email, "Remove external user from site")) {
            try {
                Remove-PnPUser -Identity $user.LoginName -Force -ErrorAction Stop
                Write-Log "  Removed: $($user.Email)" -Level SUCCESS
                $externalReport[-1].Action = "Removed"
            } catch {
                Write-Log "  Error removing '$($user.Email)': $_" -Level WARN
                $externalReport[-1].Action = "Error: $_"
            }
        }
    }

    $externalReport | Export-Csv "$OutputPath\RemovedExternals.csv" -NoTypeInformation -Encoding UTF8
    Write-Log "Report: $OutputPath\RemovedExternals.csv" -Level SUCCESS
}
#endregion

#region ── Mode: ReplaceGroup ──────────────────────────────────────────────────
if ($Mode -eq "ReplaceGroup") {
    if (-not $OldGroupName -or -not $NewGroupName) {
        Write-Log "Both -OldGroupName and -NewGroupName parameters are required for ReplaceGroup." -Level ERROR
        exit 1
    }
    Write-Log "=== REPLACING GROUP: '$OldGroupName' → '$NewGroupName' ===" -Level PHASE

    # Find the source group and its current permissions
    $oldGroup = Get-PnPGroup -Identity $OldGroupName -ErrorAction SilentlyContinue
    $newGroup = Get-PnPGroup -Identity $NewGroupName -ErrorAction SilentlyContinue

    if (-not $oldGroup) { Write-Log "Source group '$OldGroupName' not found." -Level ERROR; exit 1 }
    if (-not $newGroup) {
        Write-Log "Destination group '$NewGroupName' does not exist. Creating..." -Level WARN
        $newGroup = New-PnPGroup -Title $NewGroupName
    }

    # Get current roles of the source group on the site
    $web = Get-PnPWeb -Includes RoleAssignments
    foreach ($ra in $web.RoleAssignments) {
        if ($ra.Member.LoginName -like "*$OldGroupName*") {
            $roleDefinitions = $ra.RoleDefinitionBindings | Select-Object -ExpandProperty Name
            foreach ($role in $roleDefinitions) {
                if ($PSCmdlet.ShouldProcess($SiteUrl, "Assign role '$role' to '$NewGroupName'")) {
                    Set-PnPWebPermission -Group $NewGroupName -AddRole $role | Out-Null
                    Write-Log "  Assigned role '$role' to '$NewGroupName'" -Level SUCCESS
                }
            }
        }
    }

    # Remove the old group from the site
    if ($PSCmdlet.ShouldProcess($SiteUrl, "Remove group '$OldGroupName' from site")) {
        Set-PnPWebPermission -Group $OldGroupName -RemoveRole "Full Control" -ErrorAction SilentlyContinue
        Set-PnPWebPermission -Group $OldGroupName -RemoveRole "Edit"         -ErrorAction SilentlyContinue
        Set-PnPWebPermission -Group $OldGroupName -RemoveRole "Read"         -ErrorAction SilentlyContinue
        Write-Log "  Removed group '$OldGroupName' permissions from site." -Level SUCCESS
    }
}
#endregion

Write-Log "=== PERMISSIONS OPERATION COMPLETED ===" -Level SUCCESS
Write-Log "Log file: $LogFile" -Level SUCCESS
Disconnect-PnPOnline
