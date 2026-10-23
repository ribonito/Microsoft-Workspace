<#
.SYNOPSIS
    Reports on Microsoft Teams phone number assignments and PSTN inventory.

.DESCRIPTION
    Audits all telephone numbers assigned or available in Microsoft Teams Voice / Phone System.
    Categorizes numbers by type (Subscriber / User numbers vs Service / Call Queue / Auto Attendant numbers),
    toll vs toll-free, activation state, and geographical region. Supports interactive number inspection
    via Out-GridView.

.NOTES
    Requires MicrosoftTeams module (v4+ using Get-CsPhoneNumberAssignment).
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\Teams - Telephone Number Overview.ps1
    Retrieves and summarizes all Teams PSTN telephone numbers in the tenant.

.LINK
    https://learn.microsoft.com/powershell/module/teams/get-csphonenumberassignment
    https://learn.microsoft.com/microsoftteams/manage-phone-numbers-for-your-organization
#>

[CmdletBinding()]
param ()

# Connect to Microsoft Teams
Import-Module MicrosoftTeams -ErrorAction SilentlyContinue
Connect-MicrosoftTeams

Write-Host "Querying tenant telephone numbers in Microsoft Teams..." -ForegroundColor Cyan

$ListAllNumbers = Get-CsPhoneNumberAssignment -ErrorAction SilentlyContinue

if (-not $ListAllNumbers) {
    Write-Warning "No telephone numbers found or insufficient permissions to query phone number assignments."
    return
}

$CountTotalNumbers   = ($ListAllNumbers | Measure-Object).Count
$CountServiceNumbers = ($ListAllNumbers | Where-Object { $_.NumberType -like "*Service*" -or $_.InventoryType -eq "Service" } | Measure-Object).Count
$CountUserNumbers    = ($ListAllNumbers | Where-Object { $_.NumberType -like "*User*" -or $_.InventoryType -eq "Subscriber" } | Measure-Object).Count
$CountTollFree       = ($ListAllNumbers | Where-Object { $_.NumberType -like "*TollFree*" -or $_.Capabilities -contains "TollFree" } | Measure-Object).Count

Write-Host "`n=== Microsoft Teams Phone Number Statistics ===" -ForegroundColor Cyan
Write-Host "Total Numbers:     " -NoNewline; Write-Host $CountTotalNumbers -ForegroundColor Yellow
Write-Host "User Numbers:      " -NoNewline; Write-Host $CountUserNumbers -ForegroundColor Green
Write-Host "Service Numbers:   " -NoNewline; Write-Host $CountServiceNumbers -ForegroundColor Cyan
Write-Host "Toll Free Numbers: " -NoNewline; Write-Host $CountTollFree -ForegroundColor Magenta

# Display details table
Write-Host "`nTelephone Number Inventory:" -ForegroundColor Yellow
$ListAllNumbers |
    Select-Object TelephoneNumber, NumberType, ActivationState, AssignedPstnTargetId, City -First 50 |
    Format-Table -AutoSize
