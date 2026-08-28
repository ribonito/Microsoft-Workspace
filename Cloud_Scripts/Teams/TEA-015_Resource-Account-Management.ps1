<#
.SYNOPSIS
    TEA-015 | Resource Account Management.

.DESCRIPTION
    Create and manage Teams resource accounts.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-015 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Teams/Teams%20-%20Resource%20Account%20Management.ps1

.NOTES
    Name: TEA-015_Resource-Account-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to Teams. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module MicrosoftTeams -AllowClobber -Force -Confirm:$false;
Import-Module MicrosoftTeams;
Connect-MicrosoftTeams;

<# Create an auto-attendant resource account. #>
$User = "aa@domain.com";
$Display = "Auto Attendant Resource Account";
$IdAA = "ce933385-9390-45d1-9512-c8d228074e07";
New-CsOnlineApplicationInstance -Identity $User -ApplicationId $IdAA -DisplayName $Display;

<# Create a call queue resource account. #>
$User = "cq@domain.com";
$Display = "Call Queue Resource Account";
$IdCQ = "11cd3e2e-fccb-42ad-ad00-878b93575e07";
New-CsOnlineApplicationInstance -Identity $User -ApplicationId $IdCQ -DisplayName $Display;

<# Interactive: Select an unassigned service number to assign on a resource account. #>
$Number = (Get-CsOnlineTelephoneNumber -InventoryType Service -IsNotAssigned | Out-GridView -OutputMode Single).Id
$User = (Get-CsOnlineApplicationInstance | Out-GridView -OutputMode Single).UserPrincipalName;
Set-CsOnlineApplicationEndpoint -Uri "sip:$User" -PhoneNumber $Number;

<# Unassign a number from a resource account. #>
$User = "resource@domain.com";
Set-CsOnlineApplicationEndpoint -Identity "sip:$User" -PhoneNumber "";

<# Assign a toll number to a resource account. #>
$User = "resource@domain.com";
$Number = "+1234567890";
Set-CsOnlineApplicationEndpoint -Uri "sip:$User" -PhoneNumber $Number;

<# Assign a toll-free number to a resource account. (Make sure to have a positive communication credits balance) #>
$User = "resource@domain.com";
$Number = "+18001234567";
Set-CsOnlineApplicationEndpoint -Uri "sip:$User" -PhoneNumber $Number;

<# Assign an hybrid number to a resource account. #>
$User = "resource@domain.com";
$Number = "+11231231234";
Set-CsOnlineApplicationInstance -Identity $User -OnpremPhoneNumber $Number;