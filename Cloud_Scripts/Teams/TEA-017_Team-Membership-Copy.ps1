<#
.SYNOPSIS
    TEA-017 | Team Membership Copy.

.DESCRIPTION
    Copy team membership from one team to another.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-017 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Teams/Teams%20-%20Team%20Membership%20Copy.ps1

.NOTES
    Name: TEA-017_Team-Membership-Copy.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to Teams. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module MicrosoftTeams -AllowClobbr -Force -Confirm:$false;
Import-Module MicrosoftTeams;
Connect-MicrosoftTeams;

<# Interactive: Select source team to pull members from and add in destination team. #>
$CopyOwners = $true; $CopyMembers = $true; $CopyGuests = $true;
$SourceTeamId = (Get-Team | Out-GridView -OutputMode Single).GroupId;
$DestTeamId = (Get-Team | Where {$_.GroupId -ne $SourceTeamId} | Out-GridView -OutputMode Single).GroupId;
if ($CopyOwners -eq $true) {
	$ListOwners = Get-TeamUser -GroupId $SourceTeamId -Role Owner;
	$ListOwners | % {Add-TeamUser -GroupId $DestTeamId -User $_.UserId -Role Owner}
}
if ($CopyMembers -eq $true) {
	$ListMembers = Get-TeamUser -GroupId $SourceTeamId -Role Member;
	$ListMembers | % {Add-TeamUser -GroupId $DestTeamId -User $_.UserId}
}
if ($CopyGuests -eq $true) {
	$ListGuests = Get-TeamUser -GroupId $SourceTeamId -Role Guest;
	$ListGuests | % {Add-TeamUser -GroupId $DestTeamId -User $_.UserId}
}

<# Confirm? #>
Get-TeamUser -GroupId $SourceTeamId;
Get-TeamUser -GroupId $DestTeamId;

Get-Team -GroupId $SourceTeamId;
Get-Team -GroupId $DestTeamId;