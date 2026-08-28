<#
.SYNOPSIS
    UTL-012 | Connect to Exchange Online PowerShell.

.DESCRIPTION
    PowerShell utility script that automates loading the ExchangeOnlineManagement module 
    and establishing modern authentication connections. Includes certificate, MFA, non-MFA, 
    and environment-specific connection snippets.

.PRODUCT
    Exchange Online

.ORIGINAL_AUTHOR
    O365scripts Contributors (O365ConnectExchangeOnline classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/Connection/O365ConnectExchangeOnline.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-012 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-012_Connect-Exchange-Online.ps1
    Requires: ExchangeOnlineManagement module.

.PARAMETER AdminUpn
    The User Principal Name (UPN) of the Administrator account.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$AdminUpn = ""
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Install and connect to EXO
Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName $AdminUpn

# Connect to EXO without MFA
# $Creds = Get-Credential -UserName $AdminUpn -Message "Login:"
# Connect-ExchangeOnline -Credential $Creds

# Connect to EXO and send full debug logs to the Downloads folder
# $PathLogExo = "$env:USERPROFILE\Downloads\"
# Connect-ExchangeOnline -UserPrincipalName $AdminUpn -EnableErrorReporting -LogLevel All -LogDirectoryPath $PathLogExo

# Disconnect?
# Disconnect-ExchangeOnline -Confirm:$false

# Install/Update EXO module?
# Install-Module ExchangeOnlineManagement -Scope CurrentUser -Confirm:$false
# Update-Module ExchangeOnlineManagement -Force -Confirm:$false

# Connect to EXO using a public key certificate
# $Tenant = "tenantname"; $AppId = ""; $PathCert = ""
# Connect-ExchangeOnline -AppId $AppId -CertificateFilePath $PathCert -Organization "$Tenant.onmicrosoft.com"
#endregion
