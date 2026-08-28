<#
.SYNOPSIS
    UTL-015 | Connect to Microsoft Teams PowerShell.

.DESCRIPTION
    PowerShell utility script that automates module installation, update, and connection to Microsoft Teams. 
    Supports standard, MFA, non-MFA, and environment-specific (GCC High, DOD, China) options.

.PRODUCT
    Microsoft Teams

.ORIGINAL_AUTHOR
    O365scripts Contributors (O365ConnectMicrosoftTeams classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/Connection/O365ConnectMicrosoftTeams.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-015 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-015_Connect-Teams.ps1
    Requires: MicrosoftTeams module.

.PARAMETER AdminUpn
    The User Principal Name (UPN) of the Administrator account.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$AdminUpn = ""
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Install and connect to Teams
Install-Module MicrosoftTeams -AllowClobber -Force -Confirm:$false
Import-Module MicrosoftTeams
Connect-MicrosoftTeams

# Connect to Teams without MFA
# $Creds = Get-Credential -Message "Login:" -UserName $AdminUpn
# Connect-MicrosoftTeams -Credential $Creds

# Connect to Teams GCCH
# Connect-MicrosoftTeams -TeamsEnvironmentName TeamsGCCH

# Disconnect session?
# Disconnect-MicrosoftTeams
#endregion
