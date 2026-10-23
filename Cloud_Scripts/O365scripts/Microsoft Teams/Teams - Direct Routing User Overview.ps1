<#
.SYNOPSIS
    Reports on Enterprise Voice and Direct Routing configurations assigned to Teams users.

.DESCRIPTION
    Queries all Microsoft Teams users enabled for Enterprise Voice and Direct Routing.
    Extracts LineURI phone numbers, assigned Online Voice Routing Policies, Dial Plans,
    and voice routing configurations, producing an inventory report for telephony administrators.

.NOTES
    Requires MicrosoftTeams PowerShell module.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\Teams - Direct Routing User Overview.ps1
    Audits and displays voice-enabled Teams users with their routing policies and phone numbers.

.LINK
    https://learn.microsoft.com/microsoftteams/direct-routing-landing-page
    https://learn.microsoft.com/powershell/module/skype/get-csonlineuser
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ExportPath = "$env:USERPROFILE\Desktop\TeamsDirectRoutingUsers_$((Get-Date -Format 'yyyyMMdd_HHmmss')).csv"
)

# Connect to Microsoft Teams
Import-Module MicrosoftTeams -ErrorAction SilentlyContinue
Connect-MicrosoftTeams

Write-Host "Querying Enterprise Voice enabled users in Microsoft Teams..." -ForegroundColor Cyan

$VoiceUsers = Get-CsOnlineUser -Filter "EnterpriseVoiceEnabled -eq `$true" -ErrorAction SilentlyContinue |
    Select-Object DisplayName,
                  UserPrincipalName,
                  LineURI,
                  OnlineVoiceRoutingPolicy,
                  TenantDialPlan,
                  TeamsCallingPolicy,
                  EnterpriseVoiceEnabled

if ($VoiceUsers) {
    Write-Host "Found $(($VoiceUsers | Measure-Object).Count) Enterprise Voice user(s):" -ForegroundColor Green
    $VoiceUsers | Format-Table DisplayName, UserPrincipalName, LineURI, OnlineVoiceRoutingPolicy -AutoSize

    if (-not [string]::IsNullOrWhiteSpace($ExportPath)) {
        $VoiceUsers | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding utf8
        Write-Host "User report exported: $ExportPath" -ForegroundColor Green
    }
} else {
    Write-Warning "No users found with EnterpriseVoiceEnabled = $true."
}