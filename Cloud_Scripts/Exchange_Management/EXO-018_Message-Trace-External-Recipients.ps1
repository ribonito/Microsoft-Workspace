<#
.SYNOPSIS
    EXO-018 | Message Trace External Recipients.

.DESCRIPTION
    Trace messages sent to external recipients.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-018 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Message%20Trace%20External%20Recipients.ps1

.NOTES
    Name: EXO-018_Message-Trace-External-Recipients.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Export list of unique external addresses sent out via the onMS or by the custom domain to CSV. #>
$Domain = "domain.com";
$DomainOnms = "tenant.onmicrosoft.com";
$PathCsv = "$env:USERPROFILE\Desktop\ExportMsgTraceUniqueExternalAddresses_$((Get-Date -Format "yyyyMMddHHmmss")).csv";
Get-MessageTrace -StartDate (Get-Date).Adddays(-30) -EndDate (Get-Date) | `
	Where {$_.RecipientAddress -notlike "*$Domain" -and $_.RecipientAddress -notlike "*$DomainOnms"} | `
	Group-Object -Property RecipientAddress | Select Name | `
	Export-Csv -NoTypeInformation -Path $PathCsv;


<# Export list of unique external addresses sent out via the onMS or by multiple custom domains to CSV. #>
$Domain = "domain.com";
$Domain2 = "domain2.com";
$Domain3 = "domain3.com";
$DomainOnms = "tenant.onmicrosoft.com";
$PathCsv = "$env:USERPROFILE\Downloads\ExportMsgTraceUniqueExternalAddresses_$((Get-Date -Format "yyyyMMddHHmmss")).csv";
Get-MessageTrace -StartDate (Get-Date).Adddays(-30) -EndDate (Get-Date) | `
	Where {$_.RecipientAddress -notlike "*$Domain" -and `
		$_.RecipientAddress -notlike "*$Domain2"} -and `
		$_.RecipientAddress -notlike "*$Domain3"} -and `
		$_.RecipientAddress -notlike "*$DomainOnms"} | `
	Group-Object -Property RecipientAddress | Select Name | `
	Export-Csv -NoTypeInformation -Path $PathCsv;
