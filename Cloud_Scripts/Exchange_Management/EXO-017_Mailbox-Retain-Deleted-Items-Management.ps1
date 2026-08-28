<#
.SYNOPSIS
    EXO-017 | Mailbox Retain Deleted Items Management.

.DESCRIPTION
    Configure deleted item retention per mailbox.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-017 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Mailbox%20Retain%20Deleted%20Items%20Management.ps1

.NOTES
    Name: EXO-017_Mailbox-Retain-Deleted-Items-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Set deleted item retention to maxmimum value on all mailboxes. #>
Get-Mailbox -ResultSize Unlimited | % {Set-Mailbox -Identity $_.DistinguishedName -RetainDeletedItemsFor 30};

<# Set deleted item retention to a specific duration on a single mailbox. #>
$User = "user@domain.com";
$Retain = "d.hh:mm:ss";
Set-Mailbox -Identity $User -RetainDeletedItemsFor $Retain;
