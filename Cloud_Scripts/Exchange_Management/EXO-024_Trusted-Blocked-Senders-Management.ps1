<#
.SYNOPSIS
    EXO-024 | Trusted or Blocked Senders Management.

.DESCRIPTION
    Manage trusted and blocked sender lists on mailboxes.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-024 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Trusted%20or%20Blocked%20Senders%20Mailbox%20Management.ps1

.NOTES
    Name: EXO-024_Trusted-Blocked-Senders-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Add/remove a trusted sender on all mailboxes that do not already contain it. #>
$TrustedSender = "user@domain.com"
$ListMailbox = Get-Mailbox -ResultSize Unlimited | Select DisplayName,PrimarySmtpAddress,RecipientTypeDetails,DistinguishedName,@{Name="TrustedSendersAndDomains";Expression={(Get-MailboxJunkEmailConfiguration -Identity $_.DistinguishedName -ErrorAction SilentlyContinue).TrustedSendersAndDomains}};
$ListMailbox | Where {$_.TrustedSendersAndDomains -notcontains $TrustedSender} | % {Set-MailboxJunkEmailConfiguration -Identity $_.DistinguishedName -TrustedSendersAndDomains @{add=$TrustedSender}};
#$ListMailbox | Where {$_.TrustedSendersAndDomains -contains $TrustedSender} | % {Set-MailboxJunkEmailConfiguration -Identity $_.DistinguishedName -TrustedSendersAndDomains @{remove=$TrustedSender}};

<# Add/remove a blocked sender on all mailboxes that do not already contain it. #>
$BlockedSender = "user@domain.com"
$ListMailbox = Get-Mailbox -ResultSize Unlimited | Select DisplayName,PrimarySmtpAddress,RecipientTypeDetails,DistinguishedName,@{Name="BlockedSendersAndDomains";Expression={(Get-MailboxJunkEmailConfiguration -Identity $_.DistinguishedName -ErrorAction SilentlyContinue).BlockedSendersAndDomains}};
$ListMailbox | Where {$_.BlockedSendersAndDomains -notcontains $BlockedSender} | % {Set-MailboxJunkEmailConfiguration -Identity $_.DistinguishedName -BlockedSendersAndDomains @{add=$BlockedSender}};
#$ListMailbox | Where {$_.BlockedSendersAndDomains -contains $BlockedSender} | % {Set-MailboxJunkEmailConfiguration -Identity $_.DistinguishedName -BlockedSendersAndDomains @{remove=$BlockedSender}};
