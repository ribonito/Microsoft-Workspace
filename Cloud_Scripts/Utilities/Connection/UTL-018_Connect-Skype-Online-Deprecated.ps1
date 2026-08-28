<#
.SYNOPSIS
    UTL-018 | Connect to Skype for Business Online (Deprecated).

.DESCRIPTION
    PowerShell utility script that connects to Skype for Business Online via the legacy 
    SkypeOnlineConnector module.

.PRODUCT
    Skype for Business Online

.ORIGINAL_AUTHOR
    O365scripts Contributors (O365ConnectSkypeForBusinessOnlineDeprecated classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/Connection/O365ConnectSkypeForBusinessOnlineDeprecated.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-018 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-018_Connect-Skype-Online-Deprecated.ps1
    WARNING: Skype for Business Online is retired and the SkypeOnlineConnector module is deprecated. Use Connect-MicrosoftTeams instead.

.PARAMETER AdminUpn
    The User Principal Name (UPN) of the Administrator account.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$AdminUpn = ""
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Connect to Skype for Business Online via the legacy SFB module
Import-Module SkypeOnlineConnector
$Session_Sfb = New-CsOnlineSession -UserName $AdminUpn
Import-PSSession $Session_Sfb

# Connect to Skype for Business Online and override endpoint
# $Tenant = "tenantname"
# $Session_Sfb = New-CsOnlineSession -UserName $AdminUpn -OverrideAdminDomain "$Tenant.onmicrosoft.com"
# Import-PSSession $Session_Sfb

# Close SFB session
# Remove-PSSession $Session_Sfb
#endregion
