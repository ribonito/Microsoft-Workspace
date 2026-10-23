<#
.SYNOPSIS
    Copies membership roles (Owners, Members, Guests) from a source Team to a destination Team.

.DESCRIPTION
    Interactively or programmatically retrieves the user membership list of a specified source Team
    and replicates the owners, members, and guests into a designated destination Team. Useful during
    team restructuring, project transitions, or templating new collaboration spaces.

.PARAMETER SourceGroupId
    Optional Azure AD / M365 Group ID of the source Team. If omitted, prompts with Out-GridView.

.PARAMETER DestinationGroupId
    Optional Azure AD / M365 Group ID of the destination Team. If omitted, prompts with Out-GridView.

.PARAMETER CopyOwners
    Switch indicating whether team owners should be copied. Defaults to true.

.PARAMETER CopyMembers
    Switch indicating whether standard team members should be copied. Defaults to true.

.PARAMETER CopyGuests
    Switch indicating whether guest users should be copied. Defaults to true.

.NOTES
    Requires MicrosoftTeams module.
    Does not remove existing members from the destination team.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\Teams - Team Membership Copy.ps1
    Interactively prompts to select source and destination teams, then copies all membership roles.

.LINK
    https://learn.microsoft.com/powershell/module/teams/get-teamuser
    https://learn.microsoft.com/powershell/module/teams/add-teamuser
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$SourceGroupId,

    [Parameter(Mandatory = $false)]
    [string]$DestinationGroupId,

    [Parameter(Mandatory = $false)]
    [bool]$CopyOwners = $true,

    [Parameter(Mandatory = $false)]
    [bool]$CopyMembers = $true,

    [Parameter(Mandatory = $false)]
    [bool]$CopyGuests = $true
)

# Connect to Microsoft Teams
Import-Module MicrosoftTeams -ErrorAction SilentlyContinue
Connect-MicrosoftTeams

# Select Source Team
if ([string]::IsNullOrWhiteSpace($SourceGroupId)) {
    Write-Host "Select the SOURCE team to copy members from:" -ForegroundColor Cyan
    $SourceTeam = Get-Team | Out-GridView -Title "Select Source Team" -OutputMode Single
    if (-not $SourceTeam) { Write-Warning "No source team selected. Exiting."; return }
    $SourceGroupId = $SourceTeam.GroupId
}

# Select Destination Team
if ([string]::IsNullOrWhiteSpace($DestinationGroupId)) {
    Write-Host "Select the DESTINATION team to receive members:" -ForegroundColor Cyan
    $DestTeam = Get-Team | Where-Object { $_.GroupId -ne $SourceGroupId } | Out-GridView -Title "Select Destination Team" -OutputMode Single
    if (-not $DestTeam) { Write-Warning "No destination team selected. Exiting."; return }
    $DestinationGroupId = $DestTeam.GroupId
}

Write-Host "Copying membership from $SourceGroupId to $DestinationGroupId..." -ForegroundColor Cyan

# 1. Copy Owners
if ($CopyOwners) {
    Write-Host "Copying Owners..." -ForegroundColor Yellow
    $Owners = Get-TeamUser -GroupId $SourceGroupId -Role Owner
    foreach ($owner in $Owners) {
        try {
            Add-TeamUser -GroupId $DestinationGroupId -User $owner.UserId -Role Owner -ErrorAction SilentlyContinue
            Write-Host " Added Owner: $($owner.User)" -ForegroundColor Green
        } catch {
            Write-Warning " Failed to add owner $($owner.User): $_"
        }
    }
}

# 2. Copy Standard Members
if ($CopyMembers) {
    Write-Host "Copying Members..." -ForegroundColor Yellow
    $Members = Get-TeamUser -GroupId $SourceGroupId -Role Member
    foreach ($m in $Members) {
        try {
            Add-TeamUser -GroupId $DestinationGroupId -User $m.UserId -Role Member -ErrorAction SilentlyContinue
            Write-Host " Added Member: $($m.User)" -ForegroundColor Green
        } catch {
            Write-Warning " Failed to add member $($m.User): $_"
        }
    }
}

# 3. Copy Guests
if ($CopyGuests) {
    Write-Host "Copying Guests..." -ForegroundColor Yellow
    $Guests = Get-TeamUser -GroupId $SourceGroupId -Role Guest
    foreach ($g in $Guests) {
        try {
            Add-TeamUser -GroupId $DestinationGroupId -User $g.UserId -ErrorAction SilentlyContinue
            Write-Host " Added Guest: $($g.User)" -ForegroundColor Green
        } catch {
            Write-Warning " Failed to add guest $($g.User): $_"
        }
    }
}

Write-Host "Team membership copy operation completed." -ForegroundColor Green