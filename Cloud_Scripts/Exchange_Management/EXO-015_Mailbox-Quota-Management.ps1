<#
.SYNOPSIS
    EXO-015 | Mailbox Quota Management.

.DESCRIPTION
    Set and report mailbox storage quotas and warnings.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-015 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Mailbox%20Quota%20Management.ps1

.NOTES
    Name: EXO-015_Mailbox-Quota-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Set mailbox quota to 100GB on a single mailbox #>
$User = "";
$QuotaPsrq = "100GB";
$QuotaPsq = "99.75GB";
$QuotaIwq = "99.50GB";
Set-Mailbox $mbox -ProhibitSendReceiveQuota $QuotaPsrq -ProhibitSendQuota $QuotaPsq -IssueWarningQuota $QuotaIwq;
Get-Mailbox $mbox | Select PrimarySMTPAddress, ProhibitSendReceiveQuota, ProhibitSendQuota, IssueWarningQuota;

<# Set mailbox quota to 50GB on a single mailbox #>
$User = "";
$QuotaPsrq = "50GB";
$QuotaPsq = "49.75GB";
$QuotaIwq = "49.50GB";
Set-Mailbox $User -ProhibitSendReceiveQuota $QuotaPsrq -ProhibitSendQuota $QuotaPsq -IssueWarningQuota $QuotaIwq;
Get-Mailbox $User | Select PrimarySMTPAddress, ProhibitSendReceiveQuota, ProhibitSendQuota, IssueWarningQuota;

<# Confirm quota of all users. #>
Get-Mailbox | Select PrimarySMTPAddress, ProhibitSendReceiveQuota, ProhibitSendQuota, IssueWarningQuota;
