<#
.SYNOPSIS
    UTL-008 | Establish Legacy Connections to Exchange Online and SharePoint Online.

.DESCRIPTION
    PowerShell utility script that connects to Microsoft 365 services (Exchange Online via basic auth 
    PSSession, and SharePoint Online via Connect-SPOService) using hardcoded credential properties.

.PRODUCT
    Exchange Online / SharePoint Online / Utilities

.ORIGINAL_AUTHOR
    Martina Grom - atwork.at

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-008 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-008_Connect-Exchange-SPO-Legacy.ps1
    Requires: MSOnline modules and SharePoint Online Management Shell.
    WARNING: This script uses legacy Basic Authentication credentials which is deprecated.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
# Specifies the User account for an Office 365 global admin in your organization
$AdminAccount = '<ADMINISTRATORACCOUNT>@<TENANTNAME>.onmicrosoft.com'
$AdminPass = '<YOURPASSWORD>'
# Specifies the URL for your organization's SPO admin service
$AdminURI = "https://<TENANTNAME>-admin.sharepoint.com"
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
$encryptedPassword = ConvertTo-SecureString $AdminPass -AsPlainText -Force
$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AdminAccount, $encryptedPassword

# Remote Exchange Online connection
$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $cred -Authentication Basic -AllowRedirection
Import-PSSession $Session -AllowClobber
Write-Output "ready for Exchange Online!"

# Connect to SharePoint Online service
Connect-SPOService -Url $AdminURI -Credential $cred

Write-Host "done."
#endregion
