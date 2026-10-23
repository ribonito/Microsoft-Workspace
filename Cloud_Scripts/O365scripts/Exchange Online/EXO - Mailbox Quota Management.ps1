<#
.SYNOPSIS
    Configures and reports on Exchange Online mailbox storage quotas.

.DESCRIPTION
    Sets custom storage limits for user and shared mailboxes (ProhibitSendReceiveQuota,
    ProhibitSendQuota, IssueWarningQuota) up to the maximum supported limits (100GB for E3/E5
    licensed mailboxes). Includes procedures to verify current quota utilization across the tenant.

.PARAMETER UserPrincipalName
    The target mailbox identity to configure.

.PARAMETER QuotaSize
    Preset quota size: '50GB' or '100GB'.

.NOTES
    Requires ExchangeOnlineManagement module.
    Ensure appropriate licensing (e.g. Exchange Online Plan 2 for 100GB quotas).
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - Mailbox Quota Management.ps1 -UserPrincipalName "user@contoso.com" -QuotaSize "100GB"
    Sets the mailbox quota for user@contoso.com to 100GB limits.

.LINK
    https://learn.microsoft.com/powershell/module/exchange/set-mailbox
    https://learn.microsoft.com/exchange/recipients/user-mailboxes/storage-quotas
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$UserPrincipalName,

    [Parameter(Mandatory = $false)]
    [ValidateSet("50GB", "100GB")]
    [string]$QuotaSize = "100GB",

    [Parameter(Mandatory = $false)]
    [switch]$AuditAll
)

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline

if (-not [string]::IsNullOrWhiteSpace($UserPrincipalName)) {
    if ($QuotaSize -eq "100GB") {
        $QuotaPsrq = "100GB"
        $QuotaPsq  = "99.75GB"
        $QuotaIwq  = "99.50GB"
    } else {
        $QuotaPsrq = "50GB"
        $QuotaPsq  = "49.75GB"
        $QuotaIwq  = "49.50GB"
    }

    Write-Host "Setting $QuotaSize storage quota on mailbox '$UserPrincipalName'..." -ForegroundColor Cyan
    Set-Mailbox -Identity $UserPrincipalName `
                -ProhibitSendReceiveQuota $QuotaPsrq `
                -ProhibitSendQuota $QuotaPsq `
                -IssueWarningQuota $QuotaIwq `
                -UseDatabaseQuotaDefaults $false

    Write-Host "`nUpdated Quotas for $($UserPrincipalName):" -ForegroundColor Green
    Get-Mailbox -Identity $UserPrincipalName |
        Select-Object PrimarySmtpAddress, ProhibitSendReceiveQuota, ProhibitSendQuota, IssueWarningQuota |
        Format-Table -AutoSize
}
elseif ($AuditAll) {
    Write-Host "Auditing mailbox quotas for all mailboxes..." -ForegroundColor Cyan
    Get-EXOMailbox -ResultSize Unlimited -Properties ProhibitSendReceiveQuota, ProhibitSendQuota, IssueWarningQuota |
        Select-Object PrimarySmtpAddress, ProhibitSendReceiveQuota, ProhibitSendQuota, IssueWarningQuota |
        Format-Table -AutoSize
}
else {
    Write-Host "Usage: Specify -UserPrincipalName <UPN> to adjust a mailbox or -AuditAll to list all mailboxes." -ForegroundColor Yellow
}
