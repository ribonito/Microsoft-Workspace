<#---------------------------------------------------------------------------- 
LEGAL DISCLAIMER  
This posting is provided "AS IS" with no warranties, and confers no rights.  
 
Author: Clint Oliveira
Website: https://O365Inside.com
Version 1.0 
-Initial Release 
-Thanks to all of the Script for feedback! 
---------------------------------------------------------------------------- #>

$Title = "Detailed License Report"
$Info = "O365Inside.com By: Clint Oliveira"
 
$options = [System.Management.Automation.Host.ChoiceDescription[]] @("&All Users", "&Select Users", "&Quit")
[int]$defaultchoice = 0
$opt = $host.UI.PromptForChoice($Title , $Info, $Options, $defaultchoice)
switch($opt)
{
0 { Write-Host "All Users" -ForegroundColor Green
$OutputFile = Read-Host "Where would you like the file exported eg. c:\users\clint.oliveira\desktop\DetailedUserLicenses.csv"
Out-File -FilePath $OutputFile -InputObject "Users_UserPrincipalName, AccountSkuId, ServicePlan, ServiceStatus, GroupsAssigningLicense" -Encoding  UTF8 
$users = get-msoluser -All | Where-Object { $_.isLicensed -eq "TRUE" }

$users | foreach{
$user = Get-MsolUser -UserPrincipalName $_.userprincipalname
$Licenses = ($user).licenses
write-host "The User  $($user.UserPrincipalName) has $($Licenses.count) license Packs" -ForegroundColor Cyan
foreach ($license in $Licenses)
{
write-host "Processing  $($license.accountskuid)..." -ForegroundColor Green
$AccountSkuId = ($license).accountskuid
$GroupsAssigningLicense = ($License).GroupsAssigningLicense
$servicestatuses = $license.ServiceStatus
$Plans = ($license).ServiceStatus.serviceplan.ServiceName
$statuses = ($license).ServiceStatus.ProvisioningStatus
Foreach($servicestatus in $servicestatuses)
{
$plan=$servicestatus.ServicePlan.ServiceName
$status= $servicestatus.ProvisioningStatus
Out-File -FilePath $OutputFile -InputObject "$($user.UserPrincipalName),$($AccountSkuId),$($Plan),$($status),$($GroupsAssigningLicense)" -Encoding UTF8 -append 
write-host "`t$($user.UserPrincipalName),$($AccountSkuId),"$($Plan)",$($status),$($GroupsAssigningLicense)" 
}
}
}

}
1 { Write-Host "Select Users" -ForegroundColor Green
$InputFile = Read-Host "Enter the file path of the list of users eg. c:\users\clint.oliveira\desktop\UserList.csv"
$OutputFile = Read-Host "Where would you like the file exported eg. c:\users\clint.oliveira\desktop\DetailedUserLicenses.csv"
Out-File -FilePath $OutputFile -InputObject "Users_UserPrincipalName, AccountSkuId, ServicePlan, ServiceStatus, GroupsAssigningLicense" -Encoding  UTF8 
$csv = import-csv $InputFile

$csv | foreach{
$user = Get-MsolUser -UserPrincipalName $_.userprincipalname
$Licenses = ($user).licenses
write-host "The User  $($user.UserPrincipalName) has $($Licenses.count) license Packs" -ForegroundColor Cyan
foreach ($license in $Licenses)
{
write-host "Processing  $($license.accountskuid)..." -ForegroundColor Green
$AccountSkuId = ($license).accountskuid
$GroupsAssigningLicense = ($License).GroupsAssigningLicense
$servicestatuses = $license.ServiceStatus
$Plans = ($license).ServiceStatus.serviceplan.ServiceName
$statuses = ($license).ServiceStatus.ProvisioningStatus
Foreach($servicestatus in $servicestatuses)
{
$plan=$servicestatus.ServicePlan.ServiceName
$status= $servicestatus.ProvisioningStatus
Out-File -FilePath $OutputFile -InputObject "$($user.UserPrincipalName),$($AccountSkuId),$($Plan),$($status),$($GroupsAssigningLicense)" -Encoding UTF8 -append 
write-host "`t$($user.UserPrincipalName),$($AccountSkuId),"$($Plan)",$($status),$($GroupsAssigningLicense)" 
}
}
}
}
2 { Write-Host "Good Bye!!!" -ForegroundColor Green
	}
}