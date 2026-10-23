<#
.SYNOPSIS
    Connects to Microsoft 365 services using credential-based authentication without MFA.

.DESCRIPTION
    Automates credential-based authentication across legacy and modern M365 management modules
    (MSOnline, AzureAD, Exchange Online, Skype for Business / Teams, SharePoint Online, and PnP).
    Intended strictly for service accounts or automated lab environments where MFA cannot be used.

.NOTES
    Security Notice: Microsoft strongly recommends enforcing Multi-Factor Authentication (MFA)
    for all administrative accounts. Basic authentication is largely deprecated across Microsoft 365.
    Ensure passwords and credentials are securely handled and never hardcoded in scripts.

.EXAMPLE
    .\Connect-M365NoMFA.ps1
    Prompts for credentials once and connects to the enabled Microsoft 365 modules.

.LINK
    https://learn.microsoft.com/microsoft-365/enterprise/connect-to-all-office-365-services-in-a-single-windows-powershell-window
    https://learn.microsoft.com/security/compass/incident-response-playbook-compromised-credentials
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = "Administrative User Principal Name.")]
    [string]$AdminUpn = "admin@domain.com",

    [Parameter(Mandatory = $false, HelpMessage = "Tenant name prefix (e.g., contoso for contoso.onmicrosoft.com).")]
    [string]$Tenant = "contoso"
)

# Prompt for credentials once to reuse across sessions
$Creds = Get-Credential -Message "Enter credentials for $AdminUpn" -UserName $AdminUpn

# 1. Connect to MSOnline (Entra ID v1)
Write-Host "Connecting to MSOnline..." -ForegroundColor Cyan
Import-Module MSOnline -ErrorAction SilentlyContinue
Connect-MsolService -Credential $Creds

# 2. Connect to Azure Active Directory (Entra ID v2)
Write-Host "Connecting to AzureAD..." -ForegroundColor Cyan
Import-Module AzureAD -ErrorAction SilentlyContinue
Connect-AzureAD -AccountId $AdminUpn -Credential $Creds

# 3. Connect to Exchange Online
Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline -UserPrincipalName $AdminUpn -Credential $Creds -ShowBanner:$false

# 4. Connect to SharePoint Online Admin Center
Write-Host "Connecting to SharePoint Online..." -ForegroundColor Cyan
Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction SilentlyContinue
Connect-SPOService -Url "https://${Tenant}-admin.sharepoint.com" -Credential $Creds

# 5. Connect to SharePoint Online via PnP PowerShell
Write-Host "Connecting to PnP PowerShell..." -ForegroundColor Cyan
Import-Module PnP.PowerShell -ErrorAction SilentlyContinue
Connect-PnPOnline -Url "https://${Tenant}-admin.sharepoint.com" -Credentials $Creds

Write-Host "Non-MFA connection sequence completed." -ForegroundColor Green
