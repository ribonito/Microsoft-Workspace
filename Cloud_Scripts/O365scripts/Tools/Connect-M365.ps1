<#
.SYNOPSIS
    Quick connection utility for Microsoft 365 PowerShell management modules.

.DESCRIPTION
    Establishes administrative sessions to multiple Microsoft 365 cloud workloads,
    including Entra ID / MSOnline, Exchange Online, Security & Compliance, Microsoft Teams,
    SharePoint Online, and PnP PowerShell. Supports both interactive modern authentication
    (MFA enabled) and legacy credential-based authentication.

.NOTES
    Assumes required PowerShell modules are installed on the local system.
    Adjust connection flags ($ConnectToMSOL, $ConnectToEXO, etc.) and $AdminUpn before execution.
    Note: Do not connect to both EXO v2 and Security & Compliance concurrently in the same session.

.EXAMPLE
    .\Connect-M365.ps1
    Executes connection routine with selected services enabled.

.LINK
    https://learn.microsoft.com/microsoft-365/enterprise/connect-to-all-office-365-services-in-a-single-windows-powershell-window
    https://learn.microsoft.com/powershell/exchange/connect-to-exchange-online-powershell
    https://learn.microsoft.com/powershell/module/teams/connect-microsoftteams
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$AdminUpn = "",

    [Parameter(Mandatory = $false)]
    [string]$Tenant = "",

    [Parameter(Mandatory = $false)]
    [bool]$AdminIsMfaEnabled = $true
)

# Prompt for credentials if not using MFA interactive login
$Creds = $null
if (-not $AdminIsMfaEnabled -and -not [string]::IsNullOrWhiteSpace($AdminUpn)) {
    $Creds = Get-Credential -Message "Enter credentials for $AdminUpn" -UserName $AdminUpn
}

# -----------------------------------------------------------------------------
# Module Selection Flags (Set to 1 to connect, 0 to skip)
# -----------------------------------------------------------------------------
$ConnectToMSOL  = 0
$ConnectToAAD   = 0
$ConnectToAz    = 0
$ConnectToEXO   = 1
$ConnectToSCC   = 0
$ConnectToTeams = 0
$ConnectToSPO   = 0
$ConnectToPNP   = 0

# PnP Site URL configuration
$PnpSiteUrl = if (-not [string]::IsNullOrWhiteSpace($Tenant)) { "https://${Tenant}-admin.sharepoint.com" } else { $null }

# 1. MSOnline (Legacy Azure AD v1)
if ($ConnectToMSOL) {
    Write-Host "Connecting to MSOnline..." -ForegroundColor Cyan
    Import-Module MSOnline -ErrorAction SilentlyContinue
    if (-not $AdminIsMfaEnabled -and $Creds) { Connect-MsolService -Credential $Creds } else { Connect-MsolService }
}

# 2. AzureAD (Entra ID v2)
if ($ConnectToAAD) {
    Write-Host "Connecting to AzureAD..." -ForegroundColor Cyan
    Import-Module AzureAD -ErrorAction SilentlyContinue
    if (-not $AdminIsMfaEnabled -and $Creds) { Connect-AzureAD -AccountId $AdminUpn -Credential $Creds } else { Connect-AzureAD -AccountId $AdminUpn }
}

# 3. Azure Az Module
if ($ConnectToAz) {
    Write-Host "Connecting to Azure Az..." -ForegroundColor Cyan
    Import-Module Az -ErrorAction SilentlyContinue
    if (-not $AdminIsMfaEnabled -and $Creds) { Connect-AzAccount -Credential $Creds } else { Connect-AzAccount }
}

# 4. Exchange Online vs Security & Compliance conflict warning
if ($ConnectToEXO -and $ConnectToSCC) {
    Write-Warning "Exchange Online and Security & Compliance sessions may conflict in the same runspace."
}

# 5. Exchange Online
if ($ConnectToEXO) {
    Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
    Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
    if (-not [string]::IsNullOrWhiteSpace($AdminUpn)) {
        Connect-ExchangeOnline -UserPrincipalName $AdminUpn -ShowBanner:$false
    } else {
        Connect-ExchangeOnline -ShowBanner:$false
    }
}

# 6. Security & Compliance
if ($ConnectToSCC) {
    Write-Host "Connecting to Security & Compliance Center..." -ForegroundColor Cyan
    Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
    if (-not [string]::IsNullOrWhiteSpace($AdminUpn)) {
        Connect-IPPSSession -UserPrincipalName $AdminUpn -ShowBanner:$false
    } else {
        Connect-IPPSSession -ShowBanner:$false
    }
}

# 7. Microsoft Teams
if ($ConnectToTeams) {
    Write-Host "Connecting to Microsoft Teams..." -ForegroundColor Cyan
    Import-Module MicrosoftTeams -ErrorAction SilentlyContinue
    if (-not [string]::IsNullOrWhiteSpace($AdminUpn)) {
        Connect-MicrosoftTeams -AccountId $AdminUpn
    } else {
        Connect-MicrosoftTeams
    }
}

# 8. SharePoint Online
if ($ConnectToSPO) {
    if ([string]::IsNullOrWhiteSpace($Tenant)) {
        Write-Warning "Tenant prefix must be provided to connect to SharePoint Online Admin Center."
    } else {
        Write-Host "Connecting to SharePoint Online Admin Center..." -ForegroundColor Cyan
        Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction SilentlyContinue
        $SpoAdminUrl = "https://${Tenant}-admin.sharepoint.com"
        if (-not $AdminIsMfaEnabled -and $Creds) {
            Connect-SPOService -Url $SpoAdminUrl -Credential $Creds
        } else {
            Connect-SPOService -Url $SpoAdminUrl
        }
    }
}

# 9. PnP PowerShell
if ($ConnectToPNP) {
    if ([string]::IsNullOrWhiteSpace($PnpSiteUrl)) {
        Write-Warning "PnP site URL must be specified to connect via PnP PowerShell."
    } else {
        Write-Host "Connecting to PnP PowerShell at $PnpSiteUrl..." -ForegroundColor Cyan
        Import-Module PnP.PowerShell -ErrorAction SilentlyContinue
        Connect-PnPOnline -Url $PnpSiteUrl -Interactive
    }
}

Write-Host "PowerShell connection sequence completed." -ForegroundColor Green