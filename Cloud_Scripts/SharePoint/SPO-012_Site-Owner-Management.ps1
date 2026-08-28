<#
.SYNOPSIS
    SPO-012 | Site Owner Management.

.DESCRIPTION
    Add and remove SharePoint site collection owners.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (SPO-012 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/SharePoint%20Online/SPO%20-%20Site%20Owner%20Management.ps1

.NOTES
    Name: SPO-012_Site-Owner-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Select one or multiple security group and add each of it's members as site owners to one or multiple SPO sites. #>
$ListMembers = Get-DistributionGroup -RecipientTypeDetails MailUniversalSecurityGroup | Out-GridView -PassThru | % {Get-DistributionGroupMember -Identity $_.DistinguishedName};
$ListSites = Get-SPOSite | Out-GridView -PassThru;
ForEach ($s in $ListSites) {$ListMembers | % {Set-SPOUser -Site $s.Url -LoginName $_.PrimarySmtpAddress -IsSiteCollectionAdmin $true}}
