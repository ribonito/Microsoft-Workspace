<#
.SYNOPSIS
    EXO-002 | Exchange Online - Enable Mailbox Auditing for All User Mailboxes
    and restrict anonymous calendar sharing.

.DESCRIPTION
    This script:
        1. Connects to Exchange Online
        2. Enables mailbox auditing on all User Mailboxes with the recommended
           set of audited actions (Owner, Delegate, and Admin operations)
        3. Restricts the Default Sharing Policy to free/busy time only for
           anonymous (external) calendar sharing

    Useful as part of a new tenant hardening or security baseline deployment.

.PRODUCT
    Exchange Online

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    .\EXO-002_Enable-MailboxAuditing.ps1

.NOTES
    - Module: ExchangeOnlineManagement
    - Run with "Exchange Administrator" or higher
#>

#region ── Connection ─────────────────────────────────────────────────────────
Connect-ExchangeOnline
#endregion

#region ── Enable Mailbox Auditing (all user mailboxes) ──────────────────────
# Enables auditing and configures the key actions for Owner, Delegate and Admin
Get-Mailbox -ResultSize Unlimited -Filter { RecipientTypeDetails -eq "UserMailbox" } |
    Set-Mailbox `
        -AuditEnabled $true `
        -AuditOwner    MailboxLogin, HardDelete, SoftDelete, Update, Move `
        -AuditDelegate SendOnBehalf, MoveToDeletedItems, Move `
        -AuditAdmin    Copy, MessageBind
#endregion

#region ── Restrict Calendar Sharing (Anonymous = Free/Busy only) ─────────────
Set-SharingPolicy -Identity "Default Sharing Policy" `
    -Domains "Anonymous: CalendarSharingFreeBusySimple"
#endregion
