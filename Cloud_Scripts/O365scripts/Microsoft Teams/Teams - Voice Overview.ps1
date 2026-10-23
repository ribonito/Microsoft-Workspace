<#
.SYNOPSIS
    Generates a high-level overview of Microsoft Teams voice, telephony, and conferencing policies.

.DESCRIPTION
    Audits the current tenant configuration for Teams Voice, Dial-in Audio Conferencing,
    PSTN Direct Routing gateways, voice routing policies, and associated user statistics.
    Outputs status counts for total users, voice-enabled users, and audio conferencing users.

.NOTES
    Requires MicrosoftTeams module.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\Teams - Voice Overview.ps1
    Queries tenant voice settings and outputs summary counts and policy configurations.

.LINK
    https://learn.microsoft.com/microsoftteams/cloud-voice-landing-page
    https://learn.microsoft.com/powershell/module/skype/get-csonlineuser
#>

[CmdletBinding()]
param ()

# Connect to Microsoft Teams
Import-Module MicrosoftTeams -ErrorAction SilentlyContinue
Connect-MicrosoftTeams

Write-Host "`n=== Microsoft Teams Voice & Audio Conferencing Overview ===" -ForegroundColor Cyan

# 1. User Voice Statistics
Write-Host "`n1. User Voice Licensing & Activation Counts:" -ForegroundColor Yellow
$AllUsers          = Get-CsOnlineUser -ErrorAction SilentlyContinue
$NumUsers          = ($AllUsers | Measure-Object).Count
$NumVoiceUsers     = ($AllUsers | Where-Object { $_.EnterpriseVoiceEnabled -eq $true } | Measure-Object).Count
$NumAudioConfUsers = ($AllUsers | Where-Object { $_.TeamsUpgradeEffectiveMode -ne $null } | Measure-Object).Count

Write-Host "Total Teams Users:              " -NoNewline; Write-Host $NumUsers -ForegroundColor Green
Write-Host "Enterprise Voice Enabled Users: " -NoNewline; Write-Host $NumVoiceUsers -ForegroundColor Yellow
Write-Host "Audio Conferencing Users:       " -NoNewline; Write-Host $NumAudioConfUsers -ForegroundColor Cyan

# 2. Audio Conferencing Bridge & Tenant Settings
Write-Host "`n2. Audio Conferencing Configuration:" -ForegroundColor Yellow
Get-CsOnlineDialInConferencingBridge -ErrorAction SilentlyContinue |
    Select-Object Name, BridgeStatus, DefaultServiceNumber |
    Format-Table -AutoSize

# 3. Direct Routing Infrastructure
Write-Host "`n3. Direct Routing Gateways & Voice Routes:" -ForegroundColor Yellow
$Gateways = Get-CsOnlinePSTNGateway -ErrorAction SilentlyContinue
if ($Gateways) {
    $Gateways | Select-Object Identity, FQDN, SIPSignalingPort, Enabled | Format-Table -AutoSize
} else {
    Write-Host "No Direct Routing gateways configured." -ForegroundColor Gray
}

# 4. Teams Calling & Meeting Policies
Write-Host "`n4. Teams Calling Policies:" -ForegroundColor Yellow
Get-CsTeamsCallingPolicy -ErrorAction SilentlyContinue |
    Select-Object Identity, AllowPrivateCalling, AllowVoicemail |
    Format-Table -AutoSize

Write-Host "Teams Voice Overview completed." -ForegroundColor Green
