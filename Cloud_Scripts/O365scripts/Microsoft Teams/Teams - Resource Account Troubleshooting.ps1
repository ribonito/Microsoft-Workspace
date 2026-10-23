<#
.SYNOPSIS
    Troubleshoots Microsoft Teams voice resource accounts and user provisioning states.

.DESCRIPTION
    Audits Teams user accounts by their InterpretedUserType attribute to diagnose hybrid
    synchronization issues, misconfigurations, and resource account assignment anomalies
    for auto attendants and call queues.

.NOTES
    Requires MicrosoftTeams module.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\Teams - Resource Account Troubleshooting.ps1
    Scans for hybrid, synced, and misconfigured user types in Teams.

.LINK
    https://learn.microsoft.com/powershell/module/skype/get-csonlineuser
    https://learn.microsoft.com/microsoftteams/manage-resource-accounts
#>

[CmdletBinding()]
param ()

# Connect to Microsoft Teams
Import-Module MicrosoftTeams -ErrorAction SilentlyContinue
Connect-MicrosoftTeams

Write-Host "`n=== Microsoft Teams User & Resource Account Diagnostics ===" -ForegroundColor Cyan

# 1. Accounts synchronized via Entra Connect / AADConnect
Write-Host "`n1. Users synchronized via Entra Connect:" -ForegroundColor Yellow
$aadConnectUsers = Get-CsOnlineUser | Where-Object { $_.InterpretedUserType -match "AADConnect" }
if ($aadConnectUsers) {
    $aadConnectUsers | Select-Object UserPrincipalName, InterpretedUserType, ObjectId | Format-Table -AutoSize
} else {
    Write-Host "None found." -ForegroundColor Gray
}

# 2. Hybrid Accounts
Write-Host "`n2. Hybrid voice accounts:" -ForegroundColor Yellow
$hybridUsers = Get-CsOnlineUser | Where-Object { $_.InterpretedUserType -match "Hybrid" }
if ($hybridUsers) {
    $hybridUsers | Select-Object UserPrincipalName, InterpretedUserType, ObjectId | Format-Table -AutoSize
} else {
    Write-Host "None found." -ForegroundColor Gray
}

# 3. Misconfigured Accounts
Write-Host "`n3. Misconfigured user accounts requiring remediation:" -ForegroundColor Yellow
$misconfigured = Get-CsOnlineUser | Where-Object { $_.InterpretedUserType -match "Misconfigured" }
if ($misconfigured) {
    Write-Host "WARNING: Found $(($misconfigured | Measure-Object).Count) misconfigured account(s):" -ForegroundColor Red
    $misconfigured | Select-Object UserPrincipalName, InterpretedUserType, ObjectId | Format-Table -AutoSize
} else {
    Write-Host "No misconfigured accounts detected." -ForegroundColor Green
}
