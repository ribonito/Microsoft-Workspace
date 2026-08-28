<#
.SYNOPSIS
    TEA-019 | Team Visibility Management.

.DESCRIPTION
    Change Teams visibility (public/private) in bulk.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-019 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Teams/Teams%20-%20Team%20Visibility%20Management.ps1

.NOTES
    Name: TEA-019_Team-Visibility-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to Teams. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module MicrosoftTeams -AllowClobbr -Force -Confirm:$false;
Import-Module MicrosoftTeams;
Connect-MicrosoftTeams;

<# Set the visibility of a Team to Public/Private. #>
$TeamMail = "team@domain.com";
$TeamId = (Get-Team -MailNickName $TeamMail).GroupId;
Set-Team -GroupId $TeamId -Visibility "Public";
Set-Team -GroupId $TeamId -Visibility "Private";

<# Confirm current visibility setting is set on a Team or Channel. #>
# ...
Get-Team -GroupId $TeamId;