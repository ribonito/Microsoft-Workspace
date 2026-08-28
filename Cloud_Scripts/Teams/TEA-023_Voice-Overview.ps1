<#
.SYNOPSIS
    TEA-023 | Voice Overview.

.DESCRIPTION
    Full Teams voice configuration tenant overview.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-023 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Teams/Teams%20-%20Voice%20Overview.ps1

.NOTES
    Name: TEA-023_Voice-Overview.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to Teams. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module MicrosoftTeams -AllowClobber -Force -Confirm:$false;
Import-Module MicrosoftTeams;
Connect-MicrosoftTeams;

<# Conferencing. #>
Get-CsOnlineDialinConferencingTenantConfiguration;
Get-CsOnlineDialInConferencingTenantSettings;
Get-CsOnlineDialInConferencingBridge;
Get-CsOnlineDialinConferencingPolicy;
Get-CsTeamsAudioConferencingPolicy

<# User Count. #>
$NumUsers = (Get-CsOnlineUser).Count;
$NumVoiceUsers = (Get-CsOnlineVoiceUser).Count;
$NumAudioConfUsers = (Get-CsOnlineDialInConferencingUser).Count;
Write-Host -NoNewLine "# of Users: "; Write-Host -Fore Yellow $NumUsers;
Write-Host -NoNewLine "# of Voice Users: "; Write-Host -Fore Yellow $NumAudioConfUsers;
Write-Host -NoNewLine "# of Conferencing Users: "; Write-Host -Fore Yellow $NumVoiceUsers;

<# #>
Get-CsOnlineSipDomain;

<# Direct Routing? #>
Get-CsOnlinePSTNGateway;
Get-CsOnlineVoiceRoute;
Get-CsOnlineVoiceRoutingPolicy;
Get-CsOnlinePstnUsage;
Get-CsTeamsTranslationRule

<# #>
Get-CsTeamsMeetingPolicy;
Get-CsTeamsCallingPolicy;
#Get-CsTeamsAppPermissionPolicy;
Get-CsTeamsCallHoldPolicy
Get-CsTeamsCallParkPolicy
Get-CsTeamsComplianceRecordingApplication
#Get-CsTeamsCortanaPolicy
Get-CsTeamsGuestCallingConfiguration
Get-CsTeamsEmergencyCallingPolicy
Get-CsTeamsGuestMeetingConfiguration
Get-CsTeamsMobilityPolicy

Get-CsOnlineTelephoneNumber
Get-CsTeamsTranslationRule
Get-CsTeamsVdiPolicy
Get-CsTeamsVideoInteropServicePolicy
Get-CsTeamsWorkLoadPolicy
Get-CsTeamsNetworkRoamingPolicy
Get-CsTeamsShiftsPolicy
