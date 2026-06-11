<#
.SYNOPSIS
    SPO-005 | SharePoint Online - Post-Migration Validation and Remediation.

.DESCRIPTION
    Validates the integrity and completeness of a migration to SharePoint Online.
    Generates a detailed validation report comparing item counts, unique site permissions,
    content types, modern page availability, and unique/broken permissions on lists.
    Also provides automatic remediation for common modern features and settings.

.PRODUCT
    SharePoint Online / PnP PowerShell

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - Module: PnP.PowerShell (>= 2.x)
    - Required permissions: Access to both source and destination sites

.PARAMETER SourceUrl
    URL of the source SharePoint site (reference site).

.PARAMETER DestUrl
    URL of the destination SharePoint site to validate.

.PARAMETER ClientId
    Client ID (AppID) of the Entra ID App Registration.

.PARAMETER Thumbprint
    Thumbprint of the certificate used for app-only authentication.

.PARAMETER TenantId
    Tenant ID (Directory ID GUID) of the Entra ID tenant.

.PARAMETER ReportPath
    Local path where the validation report CSVs will be saved.

.PARAMETER AutoRemediate
    Switch. If enabled, attempts to automatically correct minor configuration discrepancies.

.EXAMPLE
    .\SPO-005_PostMigration-Validation.ps1 `
        -SourceUrl "https://contoso.sharepoint.com/sites/OldSite" `
        -DestUrl   "https://contoso.sharepoint.com/sites/NewSite" `
        -ClientId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
        -Thumbprint "AABBCC..." `
        -TenantId "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" `
        -AutoRemediate
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

#region ── Phase 1: Site Metadata ─────────────────────────────────────────────
Write-Log "=== PHASE 1: Comparing site metadata ===" -Level PHASE

Connect-ToSite -Url $SourceUrl
$srcWeb = Get-PnPWeb -Includes Title, Description, Language, MasterUrl, AlternateCssUrl, CustomMasterUrl

Connect-ToSite -Url $DestUrl
$dstWeb = Get-PnPWeb -Includes Title, Description, Language

if ($srcWeb.Title -eq $dstWeb.Title) {
    Write-Log "Title: OK ($($dstWeb.Title))" -Level SUCCESS
    Add-Result "Site Metadata" "Title" "PASS" $srcWeb.Title $dstWeb.Title
} else {
    Write-Log "Title: DIFFERENT (Source: '$($srcWeb.Title)' | Destination: '$($dstWeb.Title)')" -Level WARN
    Add-Result "Site Metadata" "Title" "WARN" $srcWeb.Title $dstWeb.Title "Titles do not match"

    if ($AutoRemediate -and $PSCmdlet.ShouldProcess($DestUrl, "Correct site title")) {
        Set-PnPWeb -Title $srcWeb.Title | Out-Null
        Write-Log "  → Title corrected automatically." -Level SUCCESS
    }
}

if ($srcWeb.Language -eq $dstWeb.Language) {
    Add-Result "Site Metadata" "Language" "PASS" $srcWeb.Language $dstWeb.Language
} else {
    Add-Result "Site Metadata" "Language" "WARN" $srcWeb.Language $dstWeb.Language "Different language settings"
    Write-Log "Language: DIFFERENT (Source: $($srcWeb.Language) | Destination: $($dstWeb.Language))" -Level WARN
}
#endregion

#region ── Phase 2: Lists and Libraries Comparison ────────────────────────────
Write-Log "=== PHASE 2: Comparing lists and document libraries ===" -Level PHASE

Connect-ToSite -Url $SourceUrl
$srcLists = Get-PnPList | Where-Object { -not $_.Hidden } | Sort-Object Title

Connect-ToSite -Url $DestUrl
$dstLists = Get-PnPList | Where-Object { -not $_.Hidden } | Sort-Object Title

Write-Log "Lists in source: $($srcLists.Count) | Destination: $($dstLists.Count)" -Level CHECK

foreach ($srcList in $srcLists) {
    $dstList = $dstLists | Where-Object { $_.Title -eq $srcList.Title }

    if (-not $dstList) {
        Write-Log "  MISSING list/library: '$($srcList.Title)'" -Level ERROR
        Add-Result "Lists/Libraries" $srcList.Title "FAIL" $srcList.ItemCount "N/A" "List not found in destination"
        continue
    }

    # Compare item counts
    $delta = [math]::Abs($srcList.ItemCount - $dstList.ItemCount)
    $pct   = if ($srcList.ItemCount -gt 0) { [math]::Round(($delta / $srcList.ItemCount) * 100, 1) } else { 0 }

    if ($pct -le 2) {
        Write-Log "  ✔ '$($srcList.Title)': $($srcList.ItemCount) source / $($dstList.ItemCount) destination" -Level SUCCESS
        Add-Result "Lists/Libraries" $srcList.Title "PASS" $srcList.ItemCount $dstList.ItemCount "$pct% delta"
    } elseif ($pct -le 10) {
        Write-Log "  ⚠ '$($srcList.Title)': delta $pct% ($($srcList.ItemCount) vs $($dstList.ItemCount))" -Level WARN
        Add-Result "Lists/Libraries" $srcList.Title "WARN" $srcList.ItemCount $dstList.ItemCount "$pct% delta - review needed"
    } else {
        Write-Log "  ✖ '$($srcList.Title)': delta $pct% ($($srcList.ItemCount) vs $($dstList.ItemCount))" -Level ERROR
        Add-Result "Lists/Libraries" $srcList.Title "FAIL" $srcList.ItemCount $dstList.ItemCount "$pct% delta - critical mismatch"
    }
}
#endregion

#region ── Phase 3: Content Types Validation ──────────────────────────────────
Write-Log "=== PHASE 3: Validating Content Types ===" -Level PHASE

Connect-ToSite -Url $SourceUrl
$srcCTs = Get-PnPContentType | Where-Object { $_.Group -notlike "*_*" -and $_.Sealed -eq $false }

Connect-ToSite -Url $DestUrl
$dstCTs = Get-PnPContentType

foreach ($ct in $srcCTs) {
    $found = $dstCTs | Where-Object { $_.Name -eq $ct.Name }
    if ($found) {
        Add-Result "Content Types" $ct.Name "PASS" $ct.Id.StringValue $found.Id.StringValue
    } else {
        Write-Log "  MISSING Content Type: '$($ct.Name)'" -Level WARN
        Add-Result "Content Types" $ct.Name "FAIL" $ct.Id.StringValue "N/A" "Not found in destination"
    }
}
#endregion

#region ── Phase 4: Permissions Validation ────────────────────────────────────
Write-Log "=== PHASE 4: Validating site permissions ===" -Level PHASE

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
            Write-Log "  Different roles for '$($perm.PrincipalName)': $srcRoles ≠ $dstRoles" -Level WARN
            Add-Result "Permissions" $perm.PrincipalName "WARN" $srcRoles $dstRoles "Roles mismatch"
        }
    } else {
        Write-Log "  Principal '$($perm.PrincipalName)' not found in destination" -Level WARN
        Add-Result "Permissions" $perm.PrincipalName "FAIL" ($perm.Roles -join ',') "N/A" "Principal missing"
    }
}
#endregion

#region ── Phase 5: Modern Pages Validation ───────────────────────────────────
Write-Log "=== PHASE 5: Validating modern pages ===" -Level PHASE

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
        Write-Log "  MISSING page: $($page.Name)" -Level WARN
        Add-Result "Pages" $page.Name "FAIL" "Exists" "Missing" "Page not migrated"
    }
}
#endregion

#region ── Phase 6: Detect Broken Permissions ─────────────────────────────────
Write-Log "=== PHASE 6: Detecting unique permissions on lists ===" -Level PHASE
Connect-ToSite -Url $DestUrl

$brokenPermItems = [System.Collections.Generic.List[PSObject]]::new()
$listsToCheck = Get-PnPList | Where-Object { -not $_.Hidden -and $_.BaseTemplate -in @(100, 101) }

foreach ($list in $listsToCheck) {
    try {
        $items = Get-PnPListItem -List $list.Title -PageSize 500 -Fields "ID","Title","FileLeafRef","HasUniqueRoleAssignments"
        $uniqueItems = $items | Where-Object { $_["HasUniqueRoleAssignments"] -eq $true }

        if ($uniqueItems.Count -gt 0) {
            Write-Log "  '$($list.Title)': $($uniqueItems.Count) item(s) with unique permissions" -Level WARN
            $brokenPermItems.Add([PSCustomObject]@{
                Library      = $list.Title
                UniqueItems  = $uniqueItems.Count
                TotalItems   = $items.Count
                Percentage   = [math]::Round(($uniqueItems.Count / [math]::Max($items.Count,1)) * 100, 1)
            })
        }
    } catch {
        Write-Log "  Error checking list '$($list.Title)': $_" -Level WARN
    }
}

$brokenPermItems | Export-Csv "$ReportPath\BrokenPermissions.csv" -NoTypeInformation -Encoding UTF8
#endregion

#region ── Phase 7: Auto-Remediation ──────────────────────────────────────────
if ($AutoRemediate) {
    Write-Log "=== PHASE 7: Running auto-remediations ===" -Level PHASE
    Connect-ToSite -Url $DestUrl

    # Enforce NoScript status on destination
    Set-PnPSite -NoScriptSite $true -ErrorAction SilentlyContinue
    Write-Log "NoScript capability enabled on destination." -Level SUCCESS

    # Reactivate modern page feature
    Enable-PnPFeature -Identity "B6917CB1-93A0-4B97-A84D-7CF49975D4EC" -Scope Web -Force -ErrorAction SilentlyContinue
    Write-Log "Modern Site Pages feature re-enabled." -Level SUCCESS
}
#endregion

#region ── Final Summary ──────────────────────────────────────────────────────
Write-Log "=== GENERATING FINAL VALIDATION REPORT ===" -Level PHASE

$validationResults | Export-Csv "$ReportPath\ValidationReport.csv" -NoTypeInformation -Encoding UTF8

$passes = ($validationResults | Where-Object { $_.Status -eq 'PASS' }).Count
$warns  = ($validationResults | Where-Object { $_.Status -eq 'WARN' }).Count
$fails  = ($validationResults | Where-Object { $_.Status -eq 'FAIL' }).Count
$total  = $validationResults.Count

$successRate = if ($total -gt 0) { [math]::Round(($passes / $total) * 100, 1) } else { 0 }

$summary = [PSCustomObject]@{
    ValidationDate   = Get-Date -Format 'yyyy-MM-dd HH:mm'
    SourceSite       = $SourceUrl
    DestinationSite  = $DestUrl
    TotalChecks      = $total
    Passed           = $passes
    Warnings         = $warns
    Failed           = $fails
    SuccessRate      = "$successRate%"
    OverallStatus    = if ($fails -eq 0 -and $warns -le 3) { "✅ FIT" } elseif ($fails -le 5) { "⚠️ REVIEW" } else { "❌ UNFIT" }
}

$summary | ConvertTo-Json | Out-File "$ReportPath\ValidationSummary.json" -Encoding UTF8

Write-Log ""
Write-Log "══════════════════════════════════════════" -Level SUCCESS
Write-Log "POST-MIGRATION VALIDATION COMPLETED"        -Level SUCCESS
Write-Log "  ✔ PASS       : $passes"                  -Level SUCCESS
Write-Log "  ⚠ WARN       : $warns"                   -Level WARN
Write-Log "  ✖ FAIL       : $fails"                   -Level ERROR
Write-Log "  Success Rate : $successRate%"            -Level SUCCESS
Write-Log "  Status       : $($summary.OverallStatus)" -Level SUCCESS
Write-Log "  Reports path : $ReportPath"              -Level SUCCESS
Write-Log "══════════════════════════════════════════" -Level SUCCESS

Disconnect-PnPOnline
#endregion
