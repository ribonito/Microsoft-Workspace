<#
.SYNOPSIS
    EXO-011 | Mailbox Alias Management.

.DESCRIPTION
    Manage SMTP aliases on Exchange Online mailboxes.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-011 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Mailbox%20Alias%20Management.ps1

.NOTES
    Name: EXO-011_Mailbox-Alias-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Add/remove a mailbox alias. #>
$User = "user@domain.com";
$Alias = "alias@domain.com";
Set-Mailbox $User -EmailAddresses @{add=$Alias};
Set-Mailbox $User -EmailAddresses @{remove=$Alias};

<# Verify aliases. #>
(Get-Mailbox $User).EmailAddresses

<# Add multiple mailbox aliases from CSV (Single column: SmtpAddress). #>
$User = "user@domain.com";
$PathCsv = "BulkAddMailboxAlias.csv";
Import-Csv $PathCsv | % {Set-Mailbox $User -EmailAddresses @{add=$_.SmtpAddress}};

<# Confirm which mailbox has a given alias. #>
$Alias = "";
Get-Recipient | Where {$_.EmailAddresses -match $Alias} | Select ExternalDirectoryObjectId,DisplayName,UserPrincipalName,EmailAddresses;