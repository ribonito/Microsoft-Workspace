<#
.SYNOPSIS
    EXO-014 | Mailbox Permission Management.

.DESCRIPTION
    Grant and revoke mailbox permissions (FullAccess, SendAs, SendOnBehalf).

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-014 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Mailbox%20Permission%20Management.ps1

.NOTES
    Name: EXO-014_Mailbox-Permission-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Get list of mailboxes and assign full access permissions to an account or a group. #>
$grant_to = "admins@domain.com";

$mbox = Get-Mailbox -ResultSize Unlimited;
#$mbox = Get-Mailbox -ResultSize Unlimited | Where {$_.RecipientTypeDetails -eq "UserMailbox"};
#$mbox = Get-Mailbox -ResultSize Unlimited | Where {$_.RecipientTypeDetails -eq "SharedMailbox"};
#$mbox = Get-Mailbox -ResultSize Unlimited | Where {$_.RecipientTypeDetails -eq "EquipmentMailbox"};
#$mbox = Get-Mailbox -ResultSize Unlimited | Where {$_.RecipientTypeDetails -eq "RoomMailbox"};

Foreach ($m in $mbox) {
	Write-Host -NoNewline "Trying to grant Full Access permissions on ";
		Write-Host -NoNewline -Fore Yellow $m.PrimarySmtpAddress;
		Write-Host -NoNewline " to ";
		Write-Host -NoNewline -Fore Yellow $grant_to;
		Write-Host -NoNewline ".";
	#Remove-MailboxPermission -Identity $m.PrimarySmtpAddress -User $grant_to -AccessRights FullAccess -InheritanceType All -Confirm:$false -ErrorAction Continue;
	Add-MailboxPermission -Identity $m.PrimarySmtpAddress -User $grant_to -AccessRights FullAccess -AutoMapping:$false -ErrorAction Continue;
	}
