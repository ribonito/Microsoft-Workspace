<#
.SYNOPSIS
    UTL-013 | Connect to Exchange Online using Basic Authentication (Deprecated).

.DESCRIPTION
    PowerShell utility script that connects to Exchange Online using legacy Basic Authentication 
    and remote PSSession. Includes steps to enable WinRM basic auth, and to load legacy MFA modules.

.PRODUCT
    Exchange Online

.ORIGINAL_AUTHOR
    O365scripts Contributors (O365ConnectExchangeOnlineBasicDeprecated classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/Connection/O365ConnectExchangeOnlineBasicDeprecated.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-013 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-013_Connect-Exchange-Online-Basic-Deprecated.ps1
    WARNING: Basic Authentication has been retired by Microsoft. This script is preserved for legacy reference only.

.PARAMETER AdminUpn
    The User Principal Name (UPN) of the Administrator account.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$AdminUpn = "admin@tenantname.onmicrosoft.com"
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Connect to EXO v1
$Creds = Get-Credential -UserName $AdminUpn -Message "Login:"
$SessionExo = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://outlook.office365.com/powershell-liveid" -Credential $Creds -Authentication Basic -AllowRedirection -SessionOption (New-PSSessionOption -IdleTimeoutMSec (30*60000))
Import-PSSession $SessionExo

# Disconnect all sessions?
# $Creds = $null; Get-PSSession | Remove-PSSession

# Load EXO MFA module from expected path within ISE or VSCode
# $PathEXOMFA = "$env:LOCALAPOPDATA\Apps\2.0\V65560L8.V1N\H4JNE5GW.V5Z\micr..tion_45baf49ae30bdb15_0010.0000_9957e8953b5cb903"
# . "$PathEXOMFA\CreateExoPSSession.ps1";
# Connect-EXOPSSession -UserPrincipalName $AdminUpn

# Is WinRM basic auth enabled?
# winrm get winrm/config/client/auth
# If basic auth is disabled run this to enable it.
# winrm set winrm/config/client/auth @{Basic="true"}
#endregion
