<#
.SYNOPSIS
    ENT-002 | Azure Device Management.

.DESCRIPTION
    Manage Entra ID registered and joined devices.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (ENT-002 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Azure%20AD/AzureDeviceManagement.ps1

.NOTES
    Name: ENT-002_Azure-Device-Management.ps1
    Integrated from O365scripts upstream repository.
#>

# Connect to Azure AD.
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false
#Install-Module AzureAD -Force -Confirm:$false
#Update-Module -Force -Confirm:$false
Import-Module AzureAD
$AdminUpn = ""
Connect-AzureAD -AccountId $AdminUpn

# Pull the list of devices where the last login was more than X days and delete the selected ones.
$Days = 60; $DatePast = Get-Date $((Get-Date).AddDays(-$Days))
Write-Host -NoNewline "Gathering list of AAD devices not used from "; Write-Host -NoNewline -Fore Yellow (Get-Date $DatePast -Format "yyyy-MM-dd HH:mm:ss"); Write-Host " until now..."
$ListDevices = Get-AzureADDevice | Where {$_.ApproximateLastLogonTimeStamp -lt $DatePast}
$ListDevices | Where {$_.ApproximateLastLogonTimeStamp -le $DatePast} | Select DisplayName,AccountEnabled,ApproximateLastLogonTimeStamp,DeviceOSType,DeviceOSVersion,DeviceTrustType,IsCompliant,IsManaged,LastDirSyncTime,ProfileType,SystemLabels,DeviceId,ObjectId | Out-GridView -PassThru
$ListDevicesToRemove = $ListDevices | Where {$_.ApproximateLastLogonTimeStamp -le $DatePast} | Select DisplayName,AccountEnabled,ApproximateLastLogonTimeStamp,DeviceOSType,DeviceOSVersion,DeviceTrustType,IsCompliant,IsManaged,LastDirSyncTime,ProfileType,SystemLabels,DeviceId,ObjectId | Out-GridView -PassThru
$ListDevicesToRemove | % {Remove-AzureADDevice -ObjectId $_.ObjectId}
