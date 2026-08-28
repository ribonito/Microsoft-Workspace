<#
.SYNOPSIS
    UTL-009 | Connect to all Office 365 / Microsoft 365 PowerShell Services.

.DESCRIPTION
    PowerShell utility script that automates the installation, update, and connection processes 
    for the most common Microsoft 365 management modules (Azure AD, AIP Service, Exchange Online, 
    MS Online, Security & Compliance, SharePoint Online, and Teams).

.PRODUCT
    Microsoft 365 / Connection Utility

.ORIGINAL_AUTHOR
    O365scripts Contributors (O365ConnectAll classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/Connection/O365ConnectAll.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-009 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-009_Connect-All.ps1
    Requires: Administrative privileges to install modules.

.PARAMETER AdminUpn
    The User Principal Name (UPN) of the Administrator account.

.PARAMETER Tenant
    The initial tenant name (subdomain of .onmicrosoft.com).
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$AdminUpn = ""
$Tenant = "tenantname"
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# System updates
Update-Module PowerShellGet -Force -Confirm:$false

# Connect to Azure AD
Install-Module AzureAD -Force -Confirm:$false
Update-Module AzureAD -Force -Confirm:$false
Import-Module AzureAD
Connect-AzureAD -AccountId $AdminUpn

# Connect to AIP
Install-Module AIPService -Force -Confirm:$false
Update-Module AIPService -Force -Confirm:$false
Import-Module AIPService
Connect-AIPService -UserPrincipalName $AdminUpn

# Connect to EXO
Install-Module ExchangeOnlineManagement -Force -Confirm:$false
Update-Module ExchangeOnlineManagement -Force -Confirm:$false
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName $AdminUpn

# Connect to MSOL
Install-Module MSOnline -Force -Confirm:$false
Update-Module MSOnline -Force -Confirm:$false
Import-Module MSOnline
Connect-MsolService

# Connect to Security & Compliance
Update-Module ExchangeOnlineManagement -Force -Confirm:$false
Import-Module ExchangeOnlineManagement
Connect-IPPSSession -UserPrincipalName $AdminUpn

# Connect to SharePoint Online
Install-Module Microsoft.Online.SharePoint.PowerShell -Force -Confirm:$false
Update-Module Microsoft.Online.SharePoint.PowerShell -Force -Confirm:$false
Import-Module Microsoft.Online.SharePoint.PowerShell
Connect-SPOService -Url "https://${Tenant}-admin.sharepoint.com"

# Connect to Teams
Install-Module MicrosoftTeams -Force -Confirm:$false
Update-Module MicrosoftTeams -Force -Confirm:$false
Import-Module MicrosoftTeams
Connect-MicrosoftTeams
#endregion
