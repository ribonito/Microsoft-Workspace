<#
.SYNOPSIS
    EXO-019 | Mobile Device Management.

.DESCRIPTION
    Manage mobile device partnerships and wipe actions.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-019 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Mobile%20Device%20Management.ps1

.NOTES
    Name: EXO-019_Mobile-Device-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Empty the list of allowed/blocked mobile devices. #>
$mbox = "";
Set-CASMailbox -Identity $mbox -ActiveSyncAllowedDeviceIDs $null;
Set-CASMailbox -Identity $mbox -ActiveSyncBlockedDeviceIDs $null;

<# Add or remove a mobile device from the list of allowed mobile devices. #>
$mbox = "";
$deviceid = "";
Set-CASMailbox -Identity $mbox -ActiveSyncAllowedDeviceIDs @{add="$deviceid"};
Set-CASMailbox -Identity $mbox -ActiveSyncAllowedDeviceIDs @{remove="$deviceid"}

<# Add or remove a mobile device from the list of blocked mobile devices. #>
$mbox = "";
$deviceid = "";
Set-CASMailbox -Identity $mbox -ActiveSyncBlockedDeviceIDs @{add="$deviceid"}
Set-CASMailbox -Identity $mbox -ActiveSyncBlockedDeviceIDs @{remove="$deviceid"}
