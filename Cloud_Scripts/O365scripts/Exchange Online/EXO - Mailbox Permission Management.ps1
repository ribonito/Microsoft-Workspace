<#
.SYNOPSIS
    Manages Exchange Online mailbox permissions (Full Access, Send As, Send on Behalf).

.DESCRIPTION
    Grants or revokes mailbox delegate permissions (such as FullAccess with AutoMapping disabled)
    for individual users, shared mailboxes, or room/equipment resources. Prevents unwanted Outlook
    client automapping bloat while ensuring secure delegated administrative or operational access.

.PARAMETER MailboxIdentity
    The target mailbox whose permissions are being adjusted.

.PARAMETER DelegateUser
    The user or security group being granted or revoked access.

.PARAMETER AccessRights
    The permission level to grant (e.g., FullAccess). Defaults to FullAccess.

.PARAMETER AutoMapping
    Boolean switch specifying whether Outlook should automatically map the delegated mailbox. Defaults to false.

.NOTES
    Requires ExchangeOnlineManagement module.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - Mailbox Permission Management.ps1 -MailboxIdentity "shared@contoso.com" -DelegateUser "helpdesk@contoso.com"
    Grants helpdesk FullAccess to shared@contoso.com with AutoMapping disabled.

.LINK
    https://learn.microsoft.com/powershell/module/exchange/add-mailboxpermission
    https://learn.microsoft.com/powershell/module/exchange/remove-mailboxpermission
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$MailboxIdentity = "shared@domain.com",

    [Parameter(Mandatory = $false)]
    [string]$DelegateUser = "admins@domain.com",

    [Parameter(Mandatory = $false)]
    [string]$AccessRights = "FullAccess",

    [Parameter(Mandatory = $false)]
    [bool]$AutoMapping = $false,

    [Parameter(Mandatory = $false)]
    [switch]$Revoke
)

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline

if ($Revoke) {
    Write-Host "Revoking $AccessRights on $MailboxIdentity for $DelegateUser..." -ForegroundColor Yellow
    Remove-MailboxPermission -Identity $MailboxIdentity `
                            -User $DelegateUser `
                            -AccessRights $AccessRights `
                            -InheritanceType All `
                            -Confirm:$false
    Write-Host "Permission revoked successfully." -ForegroundColor Green
}
else {
    Write-Host "Granting $AccessRights on $MailboxIdentity to $DelegateUser (AutoMapping: $AutoMapping)..." -ForegroundColor Cyan
    Add-MailboxPermission -Identity $MailboxIdentity `
                          -User $DelegateUser `
                          -AccessRights $AccessRights `
                          -AutoMapping:$AutoMapping
    Write-Host "Permission assigned successfully." -ForegroundColor Green
}

# Display current permissions on target mailbox
Write-Host "`nCurrent Permissions on $($MailboxIdentity):" -ForegroundColor Cyan
Get-MailboxPermission -Identity $MailboxIdentity |
    Where-Object { -not $_.IsInherited -and $_.User -notmatch "^NT AUTHORITY" } |
    Select-Object User, AccessRights, IsInherited |
    Format-Table -AutoSize
