<#
.SYNOPSIS
    Manages soft-deleted item retention duration on Exchange Online mailboxes.

.DESCRIPTION
    Configures the RetainDeletedItemsFor time span for soft-deleted messages in the Recoverable Items
    folder (Deletions). Increases retention from the default 14 days up to the maximum 30 days
    supported by Exchange Online, safeguarding against accidental message loss.

.PARAMETER Identity
    The target mailbox to configure. If omitted with -AllMailboxes, sets retention tenant-wide.

.PARAMETER RetentionDays
    The retention period in days (1 to 30). Defaults to 30 days (maximum).

.NOTES
    Requires ExchangeOnlineManagement module.
    In Exchange Online, maximum soft-deleted item retention is 30 days.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - Mailbox Retain Deleted Items Management.ps1 -Identity "user@contoso.com" -RetentionDays 30
    Configures 30-day deleted item retention for the specified user.

.LINK
    https://learn.microsoft.com/powershell/module/exchange/set-mailbox
    https://learn.microsoft.com/exchange/security-and-compliance/recoverable-items-folder/recoverable-items-folder
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Identity,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 30)]
    [int]$RetentionDays = 30,

    [Parameter(Mandatory = $false)]
    [switch]$AllMailboxes
)

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline

$timeSpan = [TimeSpan]::FromDays($RetentionDays)

if (-not [string]::IsNullOrWhiteSpace($Identity)) {
    Write-Host "Setting deleted item retention to $RetentionDays days on '$Identity'..." -ForegroundColor Cyan
    Set-Mailbox -Identity $Identity -RetainDeletedItemsFor $timeSpan
    Get-Mailbox -Identity $Identity | Select-Object PrimarySmtpAddress, RetainDeletedItemsFor | Format-Table -AutoSize
}
elseif ($AllMailboxes) {
    Write-Host "Setting deleted item retention to $RetentionDays days on all user mailboxes..." -ForegroundColor Cyan
    $mailboxes = Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited
    $count = ($mailboxes | Measure-Object).Count
    $i = 1

    foreach ($m in $mailboxes) {
        Write-Progress -Activity "Updating Deleted Item Retention" -Status "$i of $count ($($m.PrimarySmtpAddress))" -PercentComplete (($i / $count) * 100)
        Set-Mailbox -Identity $m.DistinguishedName -RetainDeletedItemsFor $timeSpan -ErrorAction SilentlyContinue
        $i++
    }
    Write-Host "Updated retention on all $count mailboxes." -ForegroundColor Green
}
else {
    Write-Host "Usage: Specify -Identity <UPN> or -AllMailboxes with -RetentionDays <1-30>." -ForegroundColor Yellow
}
