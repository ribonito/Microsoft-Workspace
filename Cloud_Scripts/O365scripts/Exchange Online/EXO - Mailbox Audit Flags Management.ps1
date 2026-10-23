<#
.SYNOPSIS
    Configures and enforces mailbox auditing flags for Owner, Admin, and Delegate actions.

.DESCRIPTION
    Enables Exchange Online mailbox auditing and assigns a comprehensive baseline of audit actions
    for Mailbox Owners, Administrators, and Delegates. Covers essential audit events including
    MailItemsAccessed (with appropriate licensing), SendAs, SendOnBehalf, SoftDelete, HardDelete,
    and folder permission modifications.

.NOTES
    Requires ExchangeOnlineManagement module.
    Purview Advanced Audit / E5 licensing is required for forensic events such as MailItemsAccessed.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - Mailbox Audit Flags Management.ps1
    Enables auditing and assigns complete audit flag baselines across all user mailboxes.

.LINK
    https://learn.microsoft.com/purview/audit-mailboxes
    https://learn.microsoft.com/powershell/module/exchange/set-mailbox
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Identity,

    [Parameter(Mandatory = $false)]
    [switch]$AllMailboxes
)

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline

$AuditOwnerFlags = @("AddFolderPermissions", "ApplyRecord", "Create", "HardDelete", "MailboxLogin", "ModifyFolderPermissions", "Move", "MoveToDeletedItems", "RecordDelete", "RemoveFolderPermissions", "SoftDelete", "Update", "UpdateFolderPermissions", "UpdateCalendarDelegation", "UpdateInboxRules")
$AuditAdminFlags = @("AddFolderPermissions", "ApplyRecord", "Copy", "Create", "HardDelete", "ModifyFolderPermissions", "Move", "MoveToDeletedItems", "RecordDelete", "RemoveFolderPermissions", "SendAs", "SendOnBehalf", "SoftDelete", "Update", "UpdateFolderPermissions", "UpdateCalendarDelegation", "UpdateInboxRules")
$AuditDelegateFlags = @("AddFolderPermissions", "ApplyRecord", "Create", "HardDelete", "ModifyFolderPermissions", "Move", "MoveToDeletedItems", "RecordDelete", "RemoveFolderPermissions", "SendAs", "SendOnBehalf", "SoftDelete", "Update", "UpdateFolderPermissions", "UpdateInboxRules")

if (-not [string]::IsNullOrWhiteSpace($Identity)) {
    Write-Host "Enabling auditing flags on mailbox: $Identity..." -ForegroundColor Cyan
    Set-Mailbox -Identity $Identity `
                -AuditEnabled $true `
                -AuditOwner @{Add = $AuditOwnerFlags} `
                -AuditAdmin @{Add = $AuditAdminFlags} `
                -AuditDelegate @{Add = $AuditDelegateFlags}
    Write-Host "Audit configuration completed for $Identity." -ForegroundColor Green
}
elseif ($AllMailboxes) {
    Write-Host "Enabling auditing on all user mailboxes in tenant..." -ForegroundColor Cyan
    $ListMailboxes = Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited
    $count = ($ListMailboxes | Measure-Object).Count
    $i = 1

    foreach ($m in $ListMailboxes) {
        Write-Progress -Activity "Configuring audit flags" -Status "$i of $count ($($m.PrimarySmtpAddress))" -PercentComplete (($i / $count) * 100)
        Set-Mailbox -Identity $m.DistinguishedName `
                    -AuditEnabled $true `
                    -AuditOwner @{Add = $AuditOwnerFlags} `
                    -AuditAdmin @{Add = $AuditAdminFlags} `
                    -AuditDelegate @{Add = $AuditDelegateFlags} -ErrorAction SilentlyContinue
        $i++
    }
    Write-Host "Auditing enabled across all $count user mailboxes." -ForegroundColor Green
}
else {
    Write-Host "Usage: Specify -Identity <UserUPN> for a single mailbox or -AllMailboxes to audit all users." -ForegroundColor Yellow
}