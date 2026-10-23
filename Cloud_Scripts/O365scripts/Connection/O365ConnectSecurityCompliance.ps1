<#
.SYNOPSIS
    Connects to Microsoft Purview / Security & Compliance Center PowerShell.

.DESCRIPTION
    Establishes an administrative session to the Security & Compliance Center via Connect-IPPSSession
    in the ExchangeOnlineManagement module. Supports both interactive modern authentication (MFA)
    and credential-based sessions.

.PARAMETER AdminUpn
    The UserPrincipalName of the administrator account.

.NOTES
    Requires ExchangeOnlineManagement module (v2 or v3).
    Do not connect to Exchange Online and Security & Compliance within the same runspace concurrently.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\O365ConnectSecurityCompliance.ps1 -AdminUpn "secadmin@contoso.com"
    Establishes a modern authentication session to Security & Compliance Center.

.LINK
    https://learn.microsoft.com/powershell/exchange/connect-to-scc-powershell
    https://learn.microsoft.com/powershell/module/exchange/connect-ippssession
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$AdminUpn
)

# Ensure ExchangeOnlineManagement module is available
if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
    Write-Host "Installing ExchangeOnlineManagement module..." -ForegroundColor Yellow
    Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false -Scope CurrentUser
}

Import-Module ExchangeOnlineManagement

Write-Host "Connecting to Microsoft Purview / Security & Compliance Center..." -ForegroundColor Cyan

if (-not [string]::IsNullOrWhiteSpace($AdminUpn)) {
    Connect-IPPSSession -UserPrincipalName $AdminUpn -ShowBanner:$false
} else {
    Connect-IPPSSession -ShowBanner:$false
}

Write-Host "Successfully connected to Security & Compliance Center session." -ForegroundColor Green
