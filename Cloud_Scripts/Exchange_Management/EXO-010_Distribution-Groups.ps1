<#
.SYNOPSIS
    EXO-010 | Distribution Groups.

.DESCRIPTION
    Create, modify, and remove distribution groups.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-010 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Distribution%20Groups.ps1

.NOTES
    Name: EXO-010_Distribution-Groups.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Get distribution groups which are set to restrict members from joining or leaving. #>
Get-DistributionGroup -Filter {{MemberDepartRestriction -eq "Closed"} -or {MemberJoinRestriction -eq "Closed"}} | Where {$_.GroupType -notmatch "SecurityEnabled"};

<# Set all distribution groups which are set to restrict members from joining or leaving to be opened. #>
$dg_depart = "Open";
$dg_join = "Open";
Get-DistributionGroup -Filter {{MemberDepartRestriction -eq "Closed"} -or {MemberJoinRestriction -eq "Closed"}} | `
	Where {$_.GroupType -notmatch "SecurityEnabled"} | Select Primary*,DisplayName,*Restriction,GroupType,WhenCreated | `
	? {Set-DistributionGroup -Identity $_.PrimarySmtpAddress -MemberJoinRestriction $dg_join -MemberDepartRestriction $dg_depart};
