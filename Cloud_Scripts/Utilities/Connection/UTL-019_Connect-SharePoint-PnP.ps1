<#
.SYNOPSIS
    UTL-019 | Connect to SharePoint Online using PnP PowerShell.

.DESCRIPTION
    PowerShell utility script that automates loading the PnP.PowerShell module and establishing 
    interactive or credential-based connections. Includes snippets to install/update the PnP module 
    and clean up legacy SharePointPnPPowerShell modules.

.PRODUCT
    SharePoint Online / PnP PowerShell

.ORIGINAL_AUTHOR
    O365scripts Contributors (O365ConnectSPOPNP classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/Connection/O365ConnectSPOPNP.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-019 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-019_Connect-SharePoint-PnP.ps1
    Requires: PnP.PowerShell module.

.PARAMETER Tenant
    The initial tenant name (subdomain of .sharepoint.com).

.PARAMETER PnpSite
    The target SharePoint Online site collection URL.

.PARAMETER AdminUpn
    The User Principal Name (UPN) of the Administrator account.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$Tenant = ""
$PnpSite = ""
$AdminUpn = ""
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Install and connect to SharePoint Online PnP
Install-Module PnP.PowerShell -AllowClobber -Force -Confirm:$false
Import-Module PnP.PowerShell
# Register-PnPManagementShellAccess
# $PnpSite = "https://${Tenant}.sharepoint.com/"
Connect-PnPOnline -Url $PnpSite -Interactive

# Confirm which PNP module version(s) is present?
Get-InstalledModule PnP.PowerShell -ErrorAction SilentlyContinue | Select-Object Name, Version

# Update the PNP module
# Update-Module PnP.PowerShell -Force -Confirm:$false

# Connect to PNP and cache credentials (no MFA)
# $Creds = Get-Credential -UserName $AdminUpn -Message "Login"
# Connect-PnPOnline -Url $PnpSite -Credentials $Creds
#endregion
