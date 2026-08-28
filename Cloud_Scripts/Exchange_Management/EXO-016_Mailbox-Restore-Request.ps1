<#
.SYNOPSIS
    EXO-016 | Mailbox Restore Request.

.DESCRIPTION
    Create and monitor mailbox restore requests.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-016 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Mailbox%20Restore%20Request.ps1

.NOTES
    Name: EXO-016_Mailbox-Restore-Request.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Which mailbox do you want restore FROM? #>
$SourceMailbox = Get-Mailbox -SoftDeletedMailbox | Select Name,PrimarySmtpAddress,ArchiveStatus,WhenCreated,ExchangeGuid,Guid,WindowsLiveId,DistinguishedName | Out-GridView -Title "Which soft-deleted mailbox do you want restore from?" -PassThru;
#$SourceMailbox = Get-Mailbox -InactiveMailboxOnly | Select Name,PrimarySmtpAddress,ArchiveStatus,WhenCreated,ExchangeGuid,Guid,DistinguishedName | Out-GridView -Title "Which deleted mailbox do you want restore from?" -PassThru;

<# Which mailbox do you want restore TO? #>
$DestMailbox = Get-Mailbox | Select Name,ExchangeGuid,PrimarySmtpAddress,WhenCreated,DistinguishedName | Out-GridView -Title "Which active mailbox do you want restore to?" -PassThru;

<# Confirm before running! #>
New-MailboxRestoreRequest -SourceMailbox $SourceMailbox.DistinguishedName -TargetMailbox $DestMailbox.DistinguishedName -AllowLegacyDNMismatch;

<# Archive mailbox enabled? #>
New-MailboxRestoreRequest -SourceMailbox $SourceMailbox.DistinguishedName -SourceIsArchive -TargetMailbox $DestMailbox.DistinguishedName -TargetIsArchive -AllowLegacyDNMismatch;

<# View current progress? #>
Get-MailboxRestoreRequest;
