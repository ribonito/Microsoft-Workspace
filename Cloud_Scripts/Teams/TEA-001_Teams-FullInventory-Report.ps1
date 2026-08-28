<#
.SYNOPSIS
    TEA-001 | Microsoft Teams - Full Teams Inventory Report.

.DESCRIPTION
    Connects to Exchange Online and Microsoft Teams to generate a comprehensive
    report of all Teams in the organization.

    Output columns per Team:
        - TeamName / TeamNickname / TeamObjectID
        - TeamOwners (comma-separated)
        - TeamMemberCount
        - NumberOfChannels / ChannelNames
        - SharePointSite URL
        - AccessType (Public/Private)
        - TeamGuests (guests in the team, or "No Guests in Team")
        - TeamMembers (all members)

    Exported to: C:\temp\TeamsDatav2.csv

.PRODUCT
    Microsoft Teams / Exchange Online

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    .\TEA-001_Teams-FullInventory-Report.ps1

.NOTES
    - Modules: ExchangeOnlineManagement, MicrosoftTeams
    - Run with "Teams Administrator" or "Global Reader" + "Teams Reader" role
    - Performance: may be slow in large tenants (1 API call per Team)
#>

#region ── Connection ─────────────────────────────────────────────────────────
Connect-ExchangeOnline -ShowBanner:$false
Connect-MicrosoftTeams
#endregion

#region ── Collect Team Data ──────────────────────────────────────────────────
$AllTeamsInOrg = (Get-Team).GroupID
$TeamList      = @()

Write-Host "This may take a few minutes for large tenants. Please wait..." -ForegroundColor Cyan

foreach ($Team in $AllTeamsInOrg) {
    $TeamGUID      = $Team.ToString()
    $TeamGroup     = Get-UnifiedGroup -Identity $Team.ToString()
    $TeamNickname  = (Get-Team | Where-Object { $_.GroupID -eq $Team }).Mailnickname
    $TeamName      = (Get-Team | Where-Object { $_.GroupID -eq $Team }).DisplayName
    $TeamOwner     = (Get-TeamUser -GroupId $Team | Where-Object { $_.Role -eq 'Owner' }).User
    $TeamUserCount = ((Get-TeamUser -GroupId $Team).UserID).Count
    $TeamMembers   = (Get-UnifiedGroupLinks -LinkType Members -Identity $Team)
    $TeamGuests    = (Get-UnifiedGroupLinks -LinkType Members -Identity $Team |
                        Where-Object { $_.Name -match "#EXT#" }).Name
    $TeamChannels  = (Get-TeamChannel -GroupId $Team).DisplayName
    $ChannelCount  = (Get-TeamChannel -GroupId $Team).ID.Count

    if (-not $TeamGuests) { $TeamGuests = "No Guests in Team" }

    $TeamList += [PSCustomObject]@{
        TeamName        = $TeamName
        TeamNickname    = $TeamNickname
        TeamObjectID    = $TeamGUID
        TeamOwners      = $TeamOwner   -join ', '
        TeamMemberCount = $TeamUserCount
        NoOfChannels    = $ChannelCount
        ChannelNames    = $TeamChannels -join ', '
        SharePointSite  = $TeamGroup.SharePointSiteURL
        AccessType      = $TeamGroup.AccessType
        TeamGuests      = $TeamGuests  -join ', '
        TeamMembers     = $TeamMembers -join ', '
    }
}
#endregion

#region ── Export ─────────────────────────────────────────────────────────────
$OutputDir  = "C:\temp"
$OutputFile = "$OutputDir\TeamsInventory_$(Get-Date -Format 'yyyyMMdd').csv"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
    Write-Host "Output directory created: $OutputDir"
}

$TeamList | Export-Csv $OutputFile -NoTypeInformation
Write-Host "Teams report exported: $($TeamList.Count) teams → $OutputFile" -ForegroundColor Green
#endregion
