<#
.SYNOPSIS
    TEA-022 | User Phone Number Management.

.DESCRIPTION
    Assign and unassign phone numbers to Teams users.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-022 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Teams/Teams%20-%20User%20Phone%20Number%20Management.ps1

.NOTES
    Name: TEA-022_User-Phone-Number-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to Teams. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module MicrosoftTeams -AllowClobber -Force -Confirm:$false;
Import-Module MicrosoftTeams;
Connect-MicrosoftTeams;

<# Assign a specific cloud number on a specific voice user. #>
$User = "user@domain.com";
$Number = "+1234567890";
Set-CsOnlineVoiceUser -Identity $User -TelephoneNumber $Number;

<# Specify manually which number and emergency location ID to assign to a specific user. #>
$User = "";
$Number = "+1234567890";
$Location = "12345678-1234-1234-1234-123412345678";
Set-CsOnlineVoiceUser -Identity $User -TelephoneNumber $Number -LocationID $Location;

<# Interactive: Select an emergency address. #>
$Location = (Get-CsOnlineLisLocation | Out-GridView -Title "Which emergency location to assign?" -OutputMode Single).LocationId;
$Location = (Get-CsOnlineLisLocation | Select CompanyName,City,ValidationStatus,HouseNumber,StreetName,StateOrProvince,CountryOrRegion,LocationId | Out-GridView -Title "Which emergency location to assign?" -OutputMode Single).LocationId;

<# Interactive: Assign selected number and location on a specific user. #>
$User = "";
$Number = (Get-CsOnlineTelephoneNumber -IsNotAssigned | Where {$_.InventoryType -eq "Subscriber"} | Select Id,InventoryType,ActivationState,O365Region,CityCode | Out-GridView -Title "Which phone number to assign?" -OutputMode Single).Id;
$Location = (Get-CsOnlineLisLocation | Select CompanyName,City,ValidationStatus,HouseNumber,StreetName,StateOrProvince,CountryOrRegion,LocationId | Out-GridView -Title "Which emergency location to assign?" -OutputMode Single).LocationId;
Set-CsOnlineVoiceUser -Identity $User -TelephoneNumber $Number -LocationID $Location;

<# Interactive: Select an emergency address and assign first available number on a specific user. #>
$User = "";
$Location = (Get-CsOnlineLisLocation | Select CompanyName,City,ValidationStatus,HouseNumber,StreetName,StateOrProvince,CountryOrRegion,LocationId | Out-GridView -Title "Which emergency location to assign?" -OutputMode Single).LocationId;
$Number = (Get-CsOnlineTelephoneNumber -IsNotAssigned)[0].Id;
Set-CsOnlineVoiceUser -Identity $User -TelephoneNumber $Number -LocationID $Location;

<# Unassign number from a specific user. #>
$User = "";
Set-CsOnlineVoiceUser -Identity $User -TelephoneNumber $null;
Set-CsOnlineVoiceUser -Identity $User -TelephoneNumber "";

<# Unassign number and location from a specific user and disable enterprise voice. #>
$User = "";
Set-CsOnlineVoiceUser -Identity $User -TelephoneNumber $null -LocationID $null;
Set-CsUser -Identity $User -EnterpriseVoiceEnabled $false;

<# Adjust the UsageLocation so it matches the country of the telephone number that will be assigned on a specific user. #>
Connect-MsolService;
$User = ""
Set-MsolUser -UserPrincipalName $User -UsageLocation "XX";
Set-CsOnlineVoiceUser -Identity $User -TelephoneNumber $Number -LocationID $Location;


<# Online vs Hybrid Unassigned User Numbers? #>
$NumberUserOnline = Get-CsOnlineTelephoneNumber -IsNotAssigned -InventoryType Subscriber;
$NumberUserHybrid = Get-CsOnlineTelephoneNumber -NumberType Hybrid -IsNotAssigned -InventoryType Subscriber;
$NumberUserHybrid; $NumberUserOnline;

<# Online vs Hybrid Unassigned Service Numbers? #>
$NumberServiceOnline = Get-CsOnlineTelephoneNumber -IsNotAssigned -InventoryType Service;
$NumberServiceHybrid = Get-CsOnlineTelephoneNumber -NumberType Hybrid -IsNotAssigned -InventoryType Service;
$NumberServiceOnline; $NumberServiceHybrid;
