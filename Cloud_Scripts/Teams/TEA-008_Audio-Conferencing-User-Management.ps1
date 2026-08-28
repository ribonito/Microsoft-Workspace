<#
.SYNOPSIS
    TEA-008 | Audio Conferencing User Management.

.DESCRIPTION
    Assign and manage audio conferencing licenses and settings.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-008 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Teams/Teams%20-%20Audio%20Conferencing%20User%20Management.ps1

.NOTES
    Name: TEA-008_Audio-Conferencing-User-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to Teams. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module MicrosoftTeams -AllowClobber -Force -Confirm:$false;
Import-Module MicrosoftTeams;
Connect-MicrosoftTeams;

<# Assign a toll conference bridge number on a user and confirm number/user details. #>
$User = "";
$TollBridge = "12223334444";
Set-CsOnlineDialInConferencingUser -Identity $User -ServiceNumber $TollBridge;
Get-CsOnlineDialInConferencingUser -Identity $User;

<# Assign a toll and toll-free conference bridge number on a user and confirm number/user details. #>
$User = "";
$TollBridge = "12223334444";
$TollFreeBridge = "18003334444";
Set-CsOnlineDialInConferencingUser -Identity $User -ServiceNumber $TollBridge;
Set-CsOnlineDialInConferencingUser -Identity $User -TollFreeServiceNumber $TollFreeBridge;
Get-CsOnlineTelephoneNumber -TelephoneNumber $TollBridge;
Get-CsOnlineTelephoneNumber -TelephoneNumber $TollFreeBridge;
Get-CsOnlineDialInConferencingUser -Identity $User;

<# DEPRECATED: Toggle on/off audio conferencing on a single user. Wait an hour in between preferably. #>
#Disable-CsOnlineDialInConferencingUser $User;
#Enable-CsOnlineDialInConferencingUser $User;

<# Export CsOnlineUser and ConferencingUser details to text. #>
$User = "";
$StampNow = Get-Date -Format "yyyyMMddhhmmss";
$PathBaseExport = "$env:USERPROFILE\Desktop";
$FormatEnumerationLimit = -1;
Get-CsOnlineUser -Identity $User | Select * | Out-File -FilePath "$PathBaseExport\Get-CsOnlineUser_$StampNow.txt" -Encoding utf8 -NoClobber;
Get-CsOnlineDialInConferencingUser -Identity $User | Out-File "$PathBaseExport\Get-CsOnlineDialInConferencingUser_$StampNow.txt" -Encoding utf8 -NoClobber;


<# Interactive selection of conference bridge number to assign on a user. #>
$User = "";
$Bridge = Get-CsOnlineDialInConferencingBridge | Select -ExpandProperty ServiceNumbers | Select Number,City,Type,IsShared,PrimaryLanguage,SecondaryLanguages | Out-GridView -OutputMode Single;
Set-CsOnlineDialInConferencingUser -Identity $User -ServiceNumber $Bridge;
Set-CsOnlineDialInConferencingUser -Identity $User -TollFreeServiceNumber $Bridge;

<# Display audio conferencing user details. #>
Get-CsOnlineDialInConferencingUser -Identity $User;

<# Conference Bridge number details. #>
Get-CsOnlineTelephoneNumber -TelephoneNumber "12223334444";

<# Get list of dedicated conference bridge numbers. #>
Get-CsOnlineTelephoneNumber -InventoryType Service | Where {$_.TargetType -eq "caa"} | Select Id,CityCode;

<# List all possible shared/dedicated bridge numbers. #>
Get-CsOnlineDialInConferencingBridge | Select -ExpandProperty ServiceNumbers | Select Number,City,IsShared;

<# Unregister a bridge number to be reassigned on a resource account or be sent for type conversion. #>
Unregister-CsOnlineDialInConferencingServiceNumber -Identity "+1234567890";
