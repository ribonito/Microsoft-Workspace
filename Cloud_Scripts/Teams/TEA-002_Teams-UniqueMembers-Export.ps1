<#
.SYNOPSIS
    TEA-002 | Microsoft Teams - Export All Unique Team Members Across All Teams.

.DESCRIPTION
    Connects to Microsoft Teams and exports a de-duplicated list of unique users
    across all Teams in the tenant, based on their UserId.

    This is useful for:
        - License audits (identifying users active in Teams)
        - Pre-migration headcount
        - Security reviews (who has access via Teams)

    Output: CSV file with unique user records (UserId, UPN, DisplayName, Role fields)

.PRODUCT
    Microsoft Teams

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    .\TEA-002_Teams-UniqueMembers-Export.ps1

.NOTES
    - Module: MicrosoftTeams
    - Requires Teams Administrator or Global Reader role
    - In large tenants this can take several minutes
#>

#region ── Connection ─────────────────────────────────────────────────────────
Connect-MicrosoftTeams
#endregion

#region ── Collect All Team Members ──────────────────────────────────────────
$Teams  = Get-Team
$Users  = @()

Write-Host "Collecting members from $($Teams.Count) teams..." -ForegroundColor Cyan

foreach ($TeamId in $Teams.GroupId) {
    $Users += Get-TeamUser -GroupId $TeamId
}
#endregion

#region ── De-duplicate and Export ────────────────────────────────────────────
$UniqueUsers = $Users | Sort-Object UserId -Unique

$OutputPath = "C:\temp\Teams-UniqueUsers_$(Get-Date -Format 'yyyyMMdd').csv"

if (-not (Test-Path "C:\temp")) {
    New-Item -ItemType Directory -Path "C:\temp" | Out-Null
}

$UniqueUsers | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host "Unique users across all Teams: $($UniqueUsers.Count)" -ForegroundColor Green
Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
#endregion
