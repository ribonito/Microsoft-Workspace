<#
.SYNOPSIS
    Generates a tenant-level inventory and statistical overview of Microsoft Teams.

.DESCRIPTION
    Queries all Microsoft Teams instances within the tenant, aggregating counts for public vs private
    teams, member rosters, and channel counts. Supports interactive team selection via Out-GridView
    and optional visibility management.

.NOTES
    Requires MicrosoftTeams module.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\Teams - Team Overview.ps1
    Retrieves all Teams in the organization and displays summary statistics and membership rosters.

.LINK
    https://learn.microsoft.com/powershell/module/teams/get-team
    https://learn.microsoft.com/powershell/module/teams/get-teamuser
#>

[CmdletBinding()]
param ()

# Connect to Microsoft Teams
Import-Module MicrosoftTeams -ErrorAction SilentlyContinue
Connect-MicrosoftTeams

Write-Host "`n=== Microsoft Teams Tenant Overview ===" -ForegroundColor Cyan

# 1. Gather all Teams in tenant
$ListAllTeams = Get-Team
$TotalTeams = ($ListAllTeams | Measure-Object).Count
$CountTeamsPublic = ($ListAllTeams | Where-Object { $_.Visibility -eq "Public" } | Measure-Object).Count
$CountTeamsPrivate = ($ListAllTeams | Where-Object { $_.Visibility -eq "Private" } | Measure-Object).Count

Write-Host "Total Teams:   " -NoNewline
Write-Host $TotalTeams -ForegroundColor Yellow
Write-Host "Public Teams:  " -NoNewline
Write-Host $CountTeamsPublic -ForegroundColor Green
Write-Host "Private Teams: " -NoNewline
Write-Host $CountTeamsPrivate -ForegroundColor Cyan

# 2. Display summary table
Write-Host "`nTeams Summary:" -ForegroundColor Yellow
$ListAllTeams | Select-Object DisplayName, Visibility, Description, GroupId | Format-Table -AutoSize

# 3. List members per team (Sample top 10 to avoid performance bottleneck in large tenants)
Write-Host "`nDisplaying membership sample for teams (first 5 teams):" -ForegroundColor Cyan
foreach ($team in ($ListAllTeams | Select-Object -First 5)) {
    Write-Host "`nTeam: $($team.DisplayName) [$($team.Visibility)]" -ForegroundColor Yellow
    Get-TeamUser -GroupId $team.GroupId |
        Select-Object User, Name, Role |
        Format-Table -AutoSize
}