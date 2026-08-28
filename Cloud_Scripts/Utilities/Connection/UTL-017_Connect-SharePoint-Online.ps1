<#
.SYNOPSIS
    UTL-017 | Connect to SharePoint Online PowerShell.

.DESCRIPTION
    PowerShell utility script that automates module loading and connection to the SharePoint Online Admin Center. 
    Includes snippets for MFA, non-MFA, and credentials mapping.

.PRODUCT
    SharePoint Online

.ORIGINAL_AUTHOR
    O365scripts Contributors (O365ConnectSharePointOnline classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/Connection/O365ConnectSharePointOnline.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-017 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-017_Connect-SharePoint-Online.ps1
    Requires: Microsoft.Online.SharePoint.PowerShell module.

.PARAMETER Tenant
    The initial tenant name (subdomain of .onmicrosoft.com).

.PARAMETER AdminUpn
    The User Principal Name (UPN) of the Administrator account.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$Tenant = "tenantname"
$AdminUpn = "admin@tenantname.onmicrosoft.com"
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Install and connect to SharePoint Online
Install-Module Microsoft.Online.SharePoint.PowerShell -AllowClobber -Force -Confirm:$false
Import-Module Microsoft.Online.SharePoint.PowerShell
Connect-SPOService -Url "https://${Tenant}-admin.sharepoint.com"

# Connect to SharePoint Online using stored credentials
# $Creds = Get-Credential -UserName $AdminUpn -Message "Login:"
# Connect-SPOService -Url "https://${Tenant}-admin.sharepoint.com" -Credential $Creds

# Confirm/Update module
# Get-Module -Name Microsoft.Online.SharePoint.PowerShell -ListAvailable | Select-Object Name, Version
# Update-Module Microsoft.Online.SharePoint.PowerShell -Force -Confirm:$false
#endregion
