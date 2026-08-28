<#
.SYNOPSIS
    EXO-012 | Mailbox Audit Flags Management.

.DESCRIPTION
    Configure mailbox audit logging flags per mailbox.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-012 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Mailbox%20Audit%20Flags%20Management.ps1

.NOTES
    Name: EXO-012_Mailbox-Audit-Flags-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;


<# Enable all regular audit flags on a specific mailbox. #>
$User = "user@domain.com";
$AuditOwnerFlags = @{Add="AddFolderPermissions", "ApplyRecord", "Create", "HardDelete", "MailboxLogin", "ModifyFolderPermissions", "Move", "MoveToDeletedItems", "RecordDelete", "RemoveFolderPermissions", "SoftDelete", "Update", "UpdateFolderPermissions", "UpdateCalendarDelegation", "UpdateInboxRules"}
$AuditAdminFlags = @{Add="AddFolderPermissions", "ApplyRecord", "Copy", "Create", "HardDelete", "ModifyFolderPermissions", "Move", "MoveToDeletedItems", "RecordDelete", "RemoveFolderPermissions", "SendAs", "SendOnBehalf", "SoftDelete", "Update", "UpdateFolderPermissions", "UpdateCalendarDelegation", "UpdateInboxRules"}
$AuditDelegateFlags = @{Add="AddFolderPermissions", "ApplyRecord", "Create", "HardDelete", "ModifyFolderPermissions", "Move", "MoveToDeletedItems", "RecordDelete", "RemoveFolderPermissions", "SendAs", "SendOnBehalf", "SoftDelete", "Update", "UpdateFolderPermissions", "UpdateInboxRules"}
Set-Mailbox -Identity $User -AuditEnabled $true -AuditAdmin $AuditAdminFlags -AuditDelegate $AuditDelegateFlags -AuditOwner $AuditOwnerFlags;

<# Enable all regular audit flags on all user mailboxes. #>
$ListMailbox = Get-Mailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited;
$ListMailbox | % {
	Write-Host -NoNewline "Enabling all audit flags on "; Write-Host -Fore Yellow $_.PrimarySmtpAddress;
	Set-Mailbox -Identity $_.DistinguishedName `
	-AuditOwner @{Add="AddFolderPermissions", "ApplyRecord", "Create", "HardDelete", "MailboxLogin", "ModifyFolderPermissions", "Move", "MoveToDeletedItems", "RecordDelete", "RemoveFolderPermissions", "SoftDelete", "Update", "UpdateFolderPermissions", "UpdateCalendarDelegation", "UpdateInboxRules"} `
	-AuditAdmin @{Add="AddFolderPermissions", "ApplyRecord", "Copy", "Create", "HardDelete", "ModifyFolderPermissions", "Move", "MoveToDeletedItems", "RecordDelete", "RemoveFolderPermissions", "SendAs", "SendOnBehalf", "SoftDelete", "Update", "UpdateFolderPermissions", "UpdateCalendarDelegation", "UpdateInboxRules"} `
	-AuditDelegate @{Add="AddFolderPermissions", "ApplyRecord", "Create", "HardDelete", "ModifyFolderPermissions", "Move", "MoveToDeletedItems", "RecordDelete", "RemoveFolderPermissions", "SendAs", "SendOnBehalf", "SoftDelete", "Update", "UpdateFolderPermissions", "UpdateInboxRules"} `
	-AuditEnabled $true};

<# Enable advanced audit flags. #>
Set-Mailbox -Identity $User -AuditOwner @{Add="MailItemsAccessed", "Send", "SearchQueryInitiated"};