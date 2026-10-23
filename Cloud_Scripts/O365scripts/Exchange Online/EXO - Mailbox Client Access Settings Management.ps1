<#
.SYNOPSIS
    Manages Client Access protocol settings (ActiveSync, POP3, IMAP4, OWA) on mailboxes.

.DESCRIPTION
    Controls protocol access permissions for Exchange ActiveSync (EAS), IMAP4, POP3, and MAPI
    on Exchange Online mailboxes. Helps enforce organization security policies by disabling legacy
    or unencrypted protocols across users or specific security groups.

.PARAMETER Identity
    The mailbox to configure. If omitted, can be applied tenant-wide or interactively.

.PARAMETER ActiveSyncEnabled
    Boolean flag to enable or disable Exchange ActiveSync. Defaults to false.

.PARAMETER ImapEnabled
    Boolean flag to enable or disable IMAP4 protocol. Defaults to false.

.PARAMETER PopEnabled
    Boolean flag to enable or disable POP3 protocol. Defaults to false.

.NOTES
    Requires ExchangeOnlineManagement module.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - Mailbox Client Access Settings Management.ps1 -Identity "user@contoso.com" -PopEnabled $false -ImapEnabled $false
    Disables legacy POP and IMAP protocols for the specified user.

.LINK
    https://learn.microsoft.com/powershell/module/exchange/set-casmailbox
    https://learn.microsoft.com/exchange/clients-and-mobile-in-exchange-online/enable-or-disable-pop3-or-imap4-access
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Identity,

    [Parameter(Mandatory = $false)]
    [bool]$ActiveSyncEnabled = $false,

    [Parameter(Mandatory = $false)]
    [bool]$ImapEnabled = $false,

    [Parameter(Mandatory = $false)]
    [bool]$PopEnabled = $false,

    [Parameter(Mandatory = $false)]
    [switch]$AllMailboxes
)

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline

if (-not [string]::IsNullOrWhiteSpace($Identity)) {
    Write-Host "Configuring CAS protocols on mailbox '$Identity'..." -ForegroundColor Cyan
    Set-CASMailbox -Identity $Identity `
                   -ActiveSyncEnabled $ActiveSyncEnabled `
                   -ImapEnabled $ImapEnabled `
                   -PopEnabled $PopEnabled
    Get-CASMailbox -Identity $Identity | Select-Object Identity, ActiveSyncEnabled, ImapEnabled, PopEnabled
}
elseif ($AllMailboxes) {
    Write-Host "Disabling legacy CAS protocols (POP/IMAP/EAS) on all mailboxes..." -ForegroundColor Cyan
    Get-EXOMailbox -ResultSize Unlimited | ForEach-Object {
        Set-CASMailbox -Identity $_.DistinguishedName `
                       -ActiveSyncEnabled $ActiveSyncEnabled `
                       -ImapEnabled $ImapEnabled `
                       -PopEnabled $PopEnabled -ErrorAction SilentlyContinue
    }
    Write-Host "Client access protocols updated tenant-wide." -ForegroundColor Green
}
else {
    Write-Host "Usage: Specify -Identity <UPN> or -AllMailboxes with desired protocol flags." -ForegroundColor Yellow
}
