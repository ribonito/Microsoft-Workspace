<#
.SYNOPSIS
    Manages Trusted (Safe) and Blocked sender lists in Exchange Online mailbox junk email settings.

.DESCRIPTION
    Configures user mailbox junk email rules via Set-MailboxJunkEmailConfiguration.
    Allows administrators to add or remove trusted (safe senders) and blocked email addresses
    or domains across individual mailboxes or tenant-wide, helping prevent phishing or ensuring
    critical partner communications bypass junk filtering.

.PARAMETER SenderEmail
    The email address or domain to add or remove from safe or blocked senders list.

.PARAMETER Action
    Action to perform: 'AddTrusted', 'RemoveTrusted', 'AddBlocked', or 'RemoveBlocked'.

.PARAMETER Identity
    Optional specific mailbox identity. If omitted, applies across all user mailboxes.

.NOTES
    Requires ExchangeOnlineManagement module.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - Trusted or Blocked Senders Mailbox Management.ps1 -SenderEmail "trustedpartner.com" -Action "AddTrusted"
    Adds trustedpartner.com to the safe senders list on all user mailboxes.

.LINK
    https://learn.microsoft.com/powershell/module/exchange/set-mailboxjunkemailconfiguration
    https://learn.microsoft.com/powershell/module/exchange/get-mailboxjunkemailconfiguration
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0)]
    [string]$SenderEmail = "partner@domain.com",

    [Parameter(Mandatory = $false)]
    [ValidateSet("AddTrusted", "RemoveTrusted", "AddBlocked", "RemoveBlocked", "Audit")]
    [string]$Action = "Audit",

    [Parameter(Mandatory = $false)]
    [string]$Identity
)

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline

Write-Host "Target sender/domain: $SenderEmail | Action: $Action" -ForegroundColor Cyan

$Mailboxes = if ($Identity) {
    Get-EXOMailbox -Identity $Identity
} else {
    Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited
}

foreach ($m in $Mailboxes) {
    $junk = Get-MailboxJunkEmailConfiguration -Identity $m.DistinguishedName -ErrorAction SilentlyContinue

    switch ($Action) {
        "AddTrusted" {
            if ($junk.TrustedSendersAndDomains -notcontains $SenderEmail) {
                Write-Host "Adding $SenderEmail to TrustedSenders on $($m.PrimarySmtpAddress)..." -ForegroundColor Green
                Set-MailboxJunkEmailConfiguration -Identity $m.DistinguishedName -TrustedSendersAndDomains @{Add = $SenderEmail}
            }
        }
        "RemoveTrusted" {
            if ($junk.TrustedSendersAndDomains -contains $SenderEmail) {
                Write-Host "Removing $SenderEmail from TrustedSenders on $($m.PrimarySmtpAddress)..." -ForegroundColor Yellow
                Set-MailboxJunkEmailConfiguration -Identity $m.DistinguishedName -TrustedSendersAndDomains @{Remove = $SenderEmail}
            }
        }
        "AddBlocked" {
            if ($junk.BlockedSendersAndDomains -notcontains $SenderEmail) {
                Write-Host "Adding $SenderEmail to BlockedSenders on $($m.PrimarySmtpAddress)..." -ForegroundColor Red
                Set-MailboxJunkEmailConfiguration -Identity $m.DistinguishedName -BlockedSendersAndDomains @{Add = $SenderEmail}
            }
        }
        "RemoveBlocked" {
            if ($junk.BlockedSendersAndDomains -contains $SenderEmail) {
                Write-Host "Removing $SenderEmail from BlockedSenders on $($m.PrimarySmtpAddress)..." -ForegroundColor Yellow
                Set-MailboxJunkEmailConfiguration -Identity $m.DistinguishedName -BlockedSendersAndDomains @{Remove = $SenderEmail}
            }
        }
        "Audit" {
            Write-Host "`nMailbox: $($m.PrimarySmtpAddress)" -ForegroundColor Yellow
            Write-Host " - Trusted: " -NoNewline; Write-Host ($junk.TrustedSendersAndDomains -join ", ") -ForegroundColor Green
            Write-Host " - Blocked: " -NoNewline; Write-Host ($junk.BlockedSendersAndDomains -join ", ") -ForegroundColor Red
        }
    }
}
