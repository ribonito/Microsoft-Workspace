<#
.SYNOPSIS
    UTL-035 | Search Email Address.

.DESCRIPTION
    Search for an email address across EXO recipient types.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-035 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Tools/Search-EmailAddress.ps1

.NOTES
    Name: UTL-035_Search-Email-Address.ps1
    Integrated from O365scripts upstream repository.
#>

$EmailAddress = "name@domain.com";
$ReportEmailAddress = "";

<# Recipients #>
$ListRecipients = Get-Recipient -ResultSize Unlimited -Filter ("EmailAddresses -like '$EmailAddress' -or PrimarySmtpAddress -eq '$EmailAddress'");
if (($ListRecipients | Measure-Object).Count -gt 1) {
	Write-Host -Fore Yellow "Found multiple possible recipients with the same email address.";
	$ListRecipients | fl DisplayName,UserPrincipalName,RecipientTypeDetails,EmailAddresses,ExternalDirectoryObjectId,DistinguishedName,WhenCreated;
}
<# Groups #>
$ListGroups = Get-DistributionGroup -Filter ("EmailAddresses -like '$EmailAddress' -or PrimarySmtpAddress -eq '$EmailAddress'")
if (($ListGroups | Measure-Object).Count -gt 1) {
	Write-Host -Fore Yellow "Found multiple possible groups with the same email address.";
	$ListGroups | fl DisplayName,UserPrincipalName,RecipientTypeDetails,EmailAddresses,ExternalDirectoryObjectId,DistinguishedName,WhenCreated;
}
<# Contacts #>
$ListContacts = Get-MailContact -Filter ("EmailAddresses -like '$EmailAddress' -or ExternalEmailAddress -eq '$EmailAddress'")
if (($ListContacts | Measure-Object).Count -gt 1) {
	Write-Host -Fore Yellow "Found multiple possible contacts with the same email address.";
	$ListContacts | fl DisplayName,UserPrincipalName,RecipientTypeDetails,EmailAddresses,ExternalDirectoryObjectId,DistinguishedName,WhenCreated;
}
<# Users #>
$ListMsolUsers = Get-MsolUser -All -SearchString "$EmailAddress";
if (($ListMsolUsers | Measure-Object).Count -gt 1) {
	Write-Host -Fore Yellow "Found multiple possible MSOL users with the same email address.";
	$ListMsolUsers | fl DisplayName,UserPrincipalName,ProxyAddresses,AlternateEmailAddresses,ObjectId,DistinguishedName,WhenCreated;
}
<# Deleted Users #>
$ListMsolDeletedUsers = Get-MsolUser -ReturnDeletedUsers | Where {$_.UserPrincipalName -eq $EmailAddress -or $_.ProxyAddresses -like $EmailAddress};
if (($ListMsolDeletedUsers | Measure-Object).Count -gt 1) {
	Write-Host -Fore Yellow "Found MSOL deleted users with the specified email address.";
	$ListMsolDeletedUsers | fl DisplayName,UserPrincipalName,ProxyAddresses,AlternateEmailAddresses,ObjectId,DistinguishedName,WhenCreated,SoftDeletionTimestamp;
}
