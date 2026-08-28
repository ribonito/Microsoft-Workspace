<#
.SYNOPSIS
    EXO-013 | Mailbox Client Access Settings Management.

.DESCRIPTION
    Manage CAS mailbox settings (MAPI, OWA, ActiveSync, etc.).

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-013 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Mailbox%20Client%20Access%20Settings%20Management.ps1

.NOTES
    Name: EXO-013_Mailbox-Client-Access-Settings-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Interactive selection of one or multiple security groups and pass through each of their members to bulk adjust EAS, POP and IMAP mail protocols. #>
$eas = $false; $imap = $false; $pop = $false;
Get-DistributionGroup -RecipientTypeDetails MailUniversalSecurityGroup | Out-GridView -PassThru | % {Get-DistributionGroupMember -Identity $_.DistinguishedName | % {Set-CasMailbox -Identity $_.DistinguishedName -ActiveSyncEnabled:$eas -ImapEnabled:$imap -PopEnabled:$pop}};

<# Toggle EAS, IMAP and POP on all mailboxes. #>
$eas = $false; $imap = $false; $pop = $false;
Get-Mailbox -ResultSize Unlimited | % {Set-CasMailbox -Identity $_.DistinguishedName -ActiveSyncEnabled:$eas -ImapEnabled:$imap -PopEnabled:$pop};
