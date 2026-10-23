<#
.SYNOPSIS
    Audits and modifies membership join and departure restrictions on distribution groups.

.DESCRIPTION
    Identifies Exchange Online distribution groups configured with restricted ("Closed") join or
    departure policies. Enables administrators to review these restrictions and optionally set them
    to "Open" or "ApprovalRequired" across all standard distribution lists.

.NOTES
    Requires ExchangeOnlineManagement module.
    Security groups are explicitly excluded as their membership cannot be managed via self-service join.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - Distribution Groups.ps1
    Audits all distribution groups with closed join or departure restrictions.

.LINK
    https://learn.microsoft.com/powershell/module/exchange/set-distributiongroup
    https://learn.microsoft.com/powershell/module/exchange/get-distributiongroup
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Open", "Closed", "ApprovalRequired")]
    [string]$MemberJoinRestriction = "Open",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Open", "Closed")]
    [string]$MemberDepartRestriction = "Open",

    [Parameter(Mandatory = $false)]
    [switch]$ApplyChanges
)

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline

Write-Host "Searching for distribution groups with closed join or leave restrictions..." -ForegroundColor Cyan

$RestrictedGroups = Get-DistributionGroup -ResultSize Unlimited |
    Where-Object {
        $_.GroupType -notmatch "SecurityEnabled" -and
        ($_.MemberDepartRestriction -eq "Closed" -or $_.MemberJoinRestriction -eq "Closed")
    } |
    Select-Object DisplayName, PrimarySmtpAddress, MemberJoinRestriction, MemberDepartRestriction, GroupType

if (-not $RestrictedGroups) {
    Write-Host "No distribution groups found with closed restrictions." -ForegroundColor Green
    return
}

Write-Host "`nFound $(($RestrictedGroups | Measure-Object).Count) restricted group(s):" -ForegroundColor Yellow
$RestrictedGroups | Format-Table -AutoSize

if ($ApplyChanges) {
    Write-Host "`nUpdating join/depart restrictions..." -ForegroundColor Cyan
    foreach ($grp in $RestrictedGroups) {
        Write-Host "Setting restrictions on $($grp.DisplayName)..." -ForegroundColor Yellow
        Set-DistributionGroup -Identity $grp.PrimarySmtpAddress `
                              -MemberJoinRestriction $MemberJoinRestriction `
                              -MemberDepartRestriction $MemberDepartRestriction
    }
    Write-Host "Restrictions updated successfully." -ForegroundColor Green
} else {
    Write-Host "`nTo apply changes, rerun with -ApplyChanges." -ForegroundColor Gray
}
