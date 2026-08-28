<#
.SYNOPSIS
    EXO-009 | Distribution Group Member Management.

.DESCRIPTION
    Add, remove, and manage distribution group members.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-009 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Distribution%20Group%20Member%20Management.ps1

.NOTES
    Name: EXO-009_Distribution-Group-Member-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>w
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Interactive selection of user(s) to be added onto one/multiple distribution groups. #>
$ListDG = Get-DistributionGroup -RecipientTypeDetails "MailUniversalDistributionGroup" -ResultSize Unlimited | Out-GridView -PassThru;
$ListUsers = Get-ExoMailbox -RecipientTypeDetails "UserMailbox" | Out-GridView -PassThru;
ForEach ($dg in $ListDG) {$ListUsers | % {Add-DistributionGroupMember -Identity $dg.DistinguishedName -Member $_.DistinguishedName -ErrorAction SilentlyContinue;}}
