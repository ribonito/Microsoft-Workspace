<#
.SYNOPSIS
    UTL-014 | Connect to Microsoft Online (MSOnline) Service.

.DESCRIPTION
    PowerShell utility script that connects to MSOnline (MSOnline module). Includes options for 
    MFA and non-MFA login, environment configuration, module installation, and cleanup.

.PRODUCT
    Microsoft 365 / MSOnline

.ORIGINAL_AUTHOR
    O365scripts Contributors (O365ConnectMicrosoftOnlineMSOL classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/Connection/O365ConnectMicrosoftOnlineMSOL.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-014 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-014_Connect-MSOnline.ps1
    Requires: MSOnline module.
    WARNING: The MSOnline module is legacy and deprecation is planned.

.PARAMETER AdminUpn
    The User Principal Name (UPN) of the Administrator account.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$AdminUpn = ""
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Install and connect to MSOL
Install-Module MSOnline -AllowClobber -Force -Confirm:$false
Import-Module MSOnline
Connect-MsolService

# Connect to MSOL without MFA
# $Creds = Get-Credential -UserName $AdminUpn -Message "Login:"
# Connect-MsolService -Credential $Creds

# Install the MSOL module as a regular user
# Install-Module MSOnline -Scope CurrentUser -AllowClobber -Force -Confirm:$false

# Completely uninstall the MSOL module
# Uninstall-Module MSOnline -AllVersions -Force -Confirm:$false -ErrorAction SilentlyContinue
#endregion
