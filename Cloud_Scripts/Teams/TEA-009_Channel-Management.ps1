<#
.SYNOPSIS
    TEA-009 | Channel Management.

.DESCRIPTION
    Add, remove, and list Teams channel members.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-009 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Teams/Teams%20-%20Channel%20Management.ps1

.NOTES
    Name: TEA-009_Channel-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Uninstall previous Teams module, add the repo and install the Teams preview module? #>
#Uninstall-Module -Name MicrosoftTeams -Force -Confirm:$false;
#Register-PSRepository -Name PSGalleryInt -SourceLocation "https://www.poshtestgallery.com/" -InstallationPolicy Trusted;
#Install-Module -Name MicrosoftTeams -Repository PSGalleryInt -Force;

<# Connect to Teams. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module MicrosoftTeams -AllowClobber -Force -Confirm:$false;
Import-Module MicrosoftTeams;
Connect-MicrosoftTeams;

<# Interactive: Get the GroupId of a single Team. #>
$TeamId = (Get-Team | Out-GridView -OutputMode Single).GroupId;

<# Interactive: Get the details of one or multiple channels of a specifc Team. #>
$ListChan = Get-TeamChannel -GroupId $TeamId | Out-GridView -PassThru ;
#$list_chan = Get-TeamChannel -GroupId $team_id -MembershipType "Private" | Out-GridView -PassThru ;
#$list_chan = Get-TeamChannel -GroupId $team_id -MembershipType "Public" | Out-GridView -PassThru ;

<# Pass through the list of selected channels to remove and readd members. #>
$ListChan | % {
	$ListChanUsers = Get-TeamChannelUser -GroupId $TeamId -DisplayName $_.DisplayName;
	<# Debug? #><#
	Write-Host -NoNewline "Channel DisplayName: "; Write-Host -Fore Yellow $_.DisplayName;
	Write-Host "Channel Users: "; $ListChanUsers;
	$PathCsv = "Teams Channel Members Output " + $_.DisplayName + ".csv";
	$ListChanUsers | Export-Csv -NoTypeInformation -Path $PathCsv;
	#>
	$ChanDisplay = $_.DisplayName;
	if ($ListChanUsers -is [system.array])
		{
		foreach ($u in $ListChanUsers)
			{
			if ($u.Role -ne "Owner")
				{
				Write-Host -NoNewline "Removing and readding <";
					Write-Host -NoNewline -Fore Yellow $u.User;
					Write-Host -NoNewline "> from the <";
					Write-Host -NoNewline -Fore Yellow $ChanDisplay;
					Write-Host "> channel.";
				#Remove-TeamChannelUser -GroupId $TeamId -DisplayName $ChanDisplay -User $u.user -ErrorAction Continue;
				#Add-TeamChannelUser -GroupId $TeamId -DisplayName $ChanDisplay -User $u.user -ErrorAction Continue;
				}
			}
		#$ChanDisplay = "";
		}
	}
