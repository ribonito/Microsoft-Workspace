<#
.SYNOPSIS
    Manages Exchange ActiveSync allowed and blocked mobile device IDs for user mailboxes.

.DESCRIPTION
    Configures ActiveSyncAllowedDeviceIDs and ActiveSyncBlockedDeviceIDs lists on individual CAS
    mailboxes. Enables administrators to explicitly allow or block mobile devices connecting
    via Exchange ActiveSync without altering tenant-wide ABQ rules.

.PARAMETER Identity
    The UserPrincipalName or primary SMTP address of the target mailbox.

.PARAMETER DeviceId
    The unique Exchange ActiveSync device identifier string to add or remove.

.PARAMETER Action
    Action to perform: 'Allow', 'Block', 'RemoveAllowed', 'RemoveBlocked', or 'ClearAll'.

.NOTES
    Requires ExchangeOnlineManagement module.
    Device IDs can be obtained using Get-MobileDevice or Get-CASMailbox.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - Mobile Device Management.ps1 -Identity "user@contoso.com" -DeviceId "ApplDN6X5080HG7C" -Action "Allow"
    Adds the specified iOS device ID to the allowed device list.

.LINK
    https://learn.microsoft.com/powershell/module/exchange/set-casmailbox
    https://learn.microsoft.com/exchange/clients-and-mobile-in-exchange-online/exchange-activesync/exchange-activesync
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Identity = "user@domain.com",

    [Parameter(Mandatory = $false)]
    [string]$DeviceId,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Allow", "Block", "RemoveAllowed", "RemoveBlocked", "ClearAll", "Audit")]
    [string]$Action = "Audit"
)

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline

switch ($Action) {
    "Allow" {
        if (-not $DeviceId) { Write-Warning "DeviceId required for Allow action."; return }
        Write-Host "Adding DeviceId '$DeviceId' to allowed list for $Identity..." -ForegroundColor Cyan
        Set-CASMailbox -Identity $Identity -ActiveSyncAllowedDeviceIDs @{Add = $DeviceId}
    }
    "Block" {
        if (-not $DeviceId) { Write-Warning "DeviceId required for Block action."; return }
        Write-Host "Adding DeviceId '$DeviceId' to blocked list for $Identity..." -ForegroundColor Cyan
        Set-CASMailbox -Identity $Identity -ActiveSyncBlockedDeviceIDs @{Add = $DeviceId}
    }
    "RemoveAllowed" {
        if (-not $DeviceId) { Write-Warning "DeviceId required for RemoveAllowed action."; return }
        Set-CASMailbox -Identity $Identity -ActiveSyncAllowedDeviceIDs @{Remove = $DeviceId}
    }
    "RemoveBlocked" {
        if (-not $DeviceId) { Write-Warning "DeviceId required for RemoveBlocked action."; return }
        Set-CASMailbox -Identity $Identity -ActiveSyncBlockedDeviceIDs @{Remove = $DeviceId}
    }
    "ClearAll" {
        Write-Host "Clearing allowed and blocked device lists for $Identity..." -ForegroundColor Yellow
        Set-CASMailbox -Identity $Identity -ActiveSyncAllowedDeviceIDs $null -ActiveSyncBlockedDeviceIDs $null
    }
    "Audit" {
        Write-Host "Auditing mobile device access for $Identity..." -ForegroundColor Cyan
    }
}

Get-CASMailbox -Identity $Identity |
    Select-Object Identity, ActiveSyncAllowedDeviceIDs, ActiveSyncBlockedDeviceIDs |
    Format-List
