<#
.SYNOPSIS
    Tests PSTN telephone number carrier portability for porting into Microsoft Teams.

.DESCRIPTION
    Validates whether a specified telephone number can be ported to Microsoft Teams Calling Plans
    using the Test-CsOnlineCarrierPortabilityIn cmdlet. Returns available porting days (FOC dates),
    supported time ranges, and minimum required porting intervals.

.PARAMETER Number
    The telephone number (in E.164 or national format) to evaluate for carrier portability.

.NOTES
    Requires MicrosoftTeams PowerShell module.
    Ensure user is assigned Teams Communications Administrator role or higher.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\Teams - Telephone Number Portability Test.ps1 -Number "+14255550100"
    Evaluates whether the specified US number can be ported into Teams.

.LINK
    https://learn.microsoft.com/powershell/module/skype/test-csonlinecarrierportabilityin
    https://learn.microsoft.com/microsoftteams/transfer-phone-numbers-to-teams
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Telephone number to test for porting eligibility.")]
    [string]$Number = "+12223334444"
)

# Connect to Microsoft Teams
Import-Module MicrosoftTeams -ErrorAction SilentlyContinue
Connect-MicrosoftTeams

Write-Host "Evaluating carrier portability for number: $Number..." -ForegroundColor Cyan

try {
    $TestPortIn = Test-CsOnlineCarrierPortabilityIn -TelephoneNumbers @($Number) -ErrorAction Stop

    Write-Host "`n=== Portability Results ===" -ForegroundColor Green
    Write-Host "Available Porting Days (Mon-Fri): " -NoNewline
    Write-Host ($TestPortIn.Carriers.FocDates -join ", ") -ForegroundColor Yellow

    Write-Host "Available Porting Hours:          " -NoNewline
    Write-Host "$($TestPortIn.Carriers.FocTimeRange.Begin) - $($TestPortIn.Carriers.FocTimeRange.End)" -ForegroundColor Yellow

    Write-Host "Minimum Porting Interval:         " -NoNewline
    Write-Host "$($TestPortIn.Carriers.MinimumPortingInterval) days" -ForegroundColor Yellow
}
catch {
    Write-Error "Failed to test carrier portability: $_"
}
