<#
.SYNOPSIS
    Generates a tenant-wide overview of Microsoft Teams Direct Routing infrastructure.

.DESCRIPTION
    Audits and reports on the tenant-level Direct Routing setup in Microsoft Teams.
    Queries Session Border Controllers (SBCs / PSTN Gateways), PSTN Usages, Voice Routes,
    and Voice Routing Policies configured in the organization.

.NOTES
    Requires MicrosoftTeams module.
    Ensure user has Teams Administrator role.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\Teams - Direct Routing Tenant Overview.ps1
    Connects to Teams and generates a comprehensive Direct Routing configuration summary.

.LINK
    https://learn.microsoft.com/microsoftteams/direct-routing-landing-page
    https://learn.microsoft.com/powershell/module/skype/get-csonlinepstngateway
#>

[CmdletBinding()]
param ()

# Connect to Microsoft Teams
Import-Module MicrosoftTeams -ErrorAction SilentlyContinue
Connect-MicrosoftTeams

Write-Host "`n=== Teams Direct Routing Infrastructure Overview ===" -ForegroundColor Cyan

# 1. Session Border Controllers (PSTN Gateways)
Write-Host "`n1. PSTN Gateways (SBCs):" -ForegroundColor Yellow
$gateways = Get-CsOnlinePSTNGateway -ErrorAction SilentlyContinue
if ($gateways) {
    $gateways | Format-Table Identity, FQDN, SIPSignalingPort, Enabled, Codecs -AutoSize
} else {
    Write-Host "No PSTN Gateways configured." -ForegroundColor Gray
}

# 2. PSTN Usages
Write-Host "`n2. PSTN Usages:" -ForegroundColor Yellow
$usages = Get-CsOnlinePstnUsage -ErrorAction SilentlyContinue
if ($usages -and $usages.Usage) {
    $usages.Usage | ForEach-Object { Write-Host " - $_" }
} else {
    Write-Host "No PSTN usages defined." -ForegroundColor Gray
}

# 3. Voice Routes
Write-Host "`n3. Voice Routes:" -ForegroundColor Yellow
$routes = Get-CsOnlineVoiceRoute -ErrorAction SilentlyContinue
if ($routes) {
    $routes | Format-Table Identity, Priority, NumberPattern, OnlinePstnGatewayList, OnlinePstnUsages -AutoSize
} else {
    Write-Host "No Voice Routes defined." -ForegroundColor Gray
}

# 4. Voice Routing Policies
Write-Host "`n4. Voice Routing Policies:" -ForegroundColor Yellow
$policies = Get-CsOnlineVoiceRoutingPolicy -ErrorAction SilentlyContinue
if ($policies) {
    $policies | Format-Table Identity, Description, OnlinePstnUsages -AutoSize
} else {
    Write-Host "No Voice Routing Policies defined." -ForegroundColor Gray
}
