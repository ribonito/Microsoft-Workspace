<#
.SYNOPSIS
    UTL-016 | Connect to Security & Compliance Center PowerShell.

.DESCRIPTION
    PowerShell utility script that automates module loading and connection to the Microsoft 365 
    Security & Compliance Center using the modern Connect-IPPSSession cmdlet.

.PRODUCT
    Microsoft 365 / Security & Compliance

.ORIGINAL_AUTHOR
    O365scripts Contributors (O365ConnectSecurityCompliance classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/Connection/O365ConnectSecurityCompliance.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-016 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-016_Connect-Security-Compliance.ps1
    Requires: ExchangeOnlineManagement module.

.PARAMETER AdminUpn
    The User Principal Name (UPN) of the Administrator account.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$AdminUpn = ""
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Install and connect to Security & Compliance
Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false
Import-Module ExchangeOnlineManagement
Connect-IPPSSession -UserPrincipalName $AdminUpn

# Connect to Security & Compliance without MFA
# $Creds = Get-Credential -UserName $AdminUpn -Message "Login"
# Connect-IPPSSession -UserPrincipalName $AdminUpn -Credential $Creds
#endregion
