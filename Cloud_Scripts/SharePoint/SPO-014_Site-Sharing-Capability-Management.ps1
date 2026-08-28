<#
.SYNOPSIS
    SPO-014 | Site Sharing Capability Management.

.DESCRIPTION
    Manage external sharing capability per site.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (SPO-014 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/SharePoint%20Online/SPO%20-%20Site%20Sharing%20Capability%20Management.ps1

.NOTES
    Name: SPO-014_Site-Sharing-Capability-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Pull list of SPO sites and configure External Sharing on the selected SPO sites. #>
$site = Get-SPOSite | select Url, SharingCapability | Out-GridView -PassThru -Title "Select the site(s) you wish to adjust external sharing...";
if ($site -ne $null) {
	$share = "Disabled","ExistingExternalUserSharingOnly","ExternalUserSharingOnly","ExternalUserAndGuestSharing";
	if ($site -is [array])
		{
		$s = $share | Out-GridView -PassThru -Title "Which sharing capability do you want to set on the sites?";
		Write-Host -Fore Yellow -NoNewline "Adjusting the following sites' external sharing setting to: "; Write-Host -Fore Red $s;
		foreach ($si in $site) {
			Set-SPOSite -Identity $si.Url -SharingCapability $s;
			Write-Host -Fore Yellow -NoNewline "Site: "; Write-Host $si.Url;
			}
		}
	else {
		$s = $share | Out-GridView -PassThru -Title "Which sharing capability do you want set on the site?";
		Set-SPOSite -Identity $site.Url -SharingCapability $s;
		Write-Host -Fore Yellow -NoNewline "Site: "; Write-Host $site.Url;
		Write-Host -Fore Yellow -NoNewline "Sharing: "; Write-Host $s; Write-Host "";
		}
	}


<# Pull list of ODfB sites and configure External Sharing on the selected ODfB sites. #>
$site = Get-SPOSite | select Url, SharingCapability | Out-GridView -PassThru -Title "Select the site(s) you wish to adjust external sharing...";
if ($site -ne $null) {
	$share = "Disabled","ExistingExternalUserSharingOnly","ExternalUserSharingOnly","ExternalUserAndGuestSharing";
	if ($site -is [array])
		{
		$s = $share | Out-GridView -PassThru -Title "Which sharing capability do you want to set on the sites?";
		Write-Host -Fore Yellow -NoNewline "Adjusting the following sites' external sharing setting to: "; Write-Host -Fore Red $s;
		foreach ($si in $site) {
			Set-SPOSite -Identity $si.Url -SharingCapability $s;
			Write-Host -Fore Yellow -NoNewline "Site: "; Write-Host $si.Url;
			}
		}
	else {
		$s = $share | Out-GridView -PassThru -Title "Which sharing capability do you want set on the site?";
		Set-SPOSite -Identity $site.Url -SharingCapability $s;
		Write-Host -Fore Yellow -NoNewline "Site: "; Write-Host $site.Url;
		Write-Host -Fore Yellow -NoNewline "Sharing: "; Write-Host $s; Write-Host "";
		}
	}
