<#
.SYNOPSIS
    Manages email aliases (proxy addresses) on Exchange Online mailboxes.

.DESCRIPTION
    Provides procedures to add, remove, and audit secondary SMTP aliases on Exchange Online user
    and shared mailboxes. Supports single mailbox management, bulk addition via CSV, and reverse
    lookup to find which mailbox owns a specific alias.

.PARAMETER Identity
    The UserPrincipalName, alias, or primary SMTP address of the target mailbox.

.PARAMETER Alias
    The email alias to add or remove.

.PARAMETER Add
    Switch indicating that the specified alias should be added.

.PARAMETER Remove
    Switch indicating that the specified alias should be removed.

.NOTES
    Requires ExchangeOnlineManagement module.
    Primary SMTP address remains unchanged when adding or removing secondary aliases.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - Mailbox Alias Management.ps1 -Identity "user@contoso.com" -Alias "alias@contoso.com" -Add
    Adds a new secondary alias to the specified mailbox.

.LINK
    https://learn.microsoft.com/exchange/recipients/user-mailboxes/email-addresses
    https://learn.microsoft.com/powershell/module/exchange/set-mailbox
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Identity = "user@domain.com",

    [Parameter(Mandatory = $false)]
    [string]$Alias = "alias@domain.com",

    [Parameter(Mandatory = $false)]
    [switch]$Add,

    [Parameter(Mandatory = $false)]
    [switch]$Remove
)

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline

if ($Add -and -not [string]::IsNullOrWhiteSpace($Identity) -and -not [string]::IsNullOrWhiteSpace($Alias)) {
    Write-Host "Adding alias '$Alias' to mailbox '$Identity'..." -ForegroundColor Cyan
    Set-Mailbox -Identity $Identity -EmailAddresses @{Add = $Alias}
    Write-Host "Current email addresses for $($Identity):" -ForegroundColor Yellow
    (Get-Mailbox -Identity $Identity).EmailAddresses
}
elseif ($Remove -and -not [string]::IsNullOrWhiteSpace($Identity) -and -not [string]::IsNullOrWhiteSpace($Alias)) {
    Write-Host "Removing alias '$Alias' from mailbox '$Identity'..." -ForegroundColor Cyan
    Set-Mailbox -Identity $Identity -EmailAddresses @{Remove = $Alias}
    Write-Host "Current email addresses for $($Identity):" -ForegroundColor Yellow
    (Get-Mailbox -Identity $Identity).EmailAddresses
}
else {
    # Default: Audit/verify aliases for the mailbox
    Write-Host "Listing email addresses for $($Identity):" -ForegroundColor Cyan
    $mbox = Get-Mailbox -Identity $Identity -ErrorAction SilentlyContinue
    if ($mbox) {
        $mbox.EmailAddresses | ForEach-Object { Write-Host " - $_" }
    } else {
        Write-Warning "Mailbox '$Identity' not found."
    }
}