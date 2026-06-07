
Connect-ExchangeOnline

Get-Mailbox -ResultSize Unlimited -Filter{RecipientTypeDetails -eq "UserMailbox"} | Set-Mailbox -AuditEnabled $true -AuditOwner MailboxLogin, HardDelete, SoftDelete, Update, Move -AuditDelegate SendOnBehalf, MoveToDeletedItems, Move -AuditAdmin Copy, MessageBind

Set-SharingPolicy -Identity "Default Sharing Policy" -Domains "Anonymous: CalendarSharingFreeBusySimple"