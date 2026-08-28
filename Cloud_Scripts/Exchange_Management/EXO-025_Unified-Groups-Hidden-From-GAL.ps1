<#
.SYNOPSIS
    EXO-025 | Unified Groups Hidden from GAL.

.DESCRIPTION
    Show or hide Microsoft 365 Groups from GAL and Outlook.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-025 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Unified%20Groups%20Hidden%20from%20GAL%20or%20Outlook.ps1

.NOTES
    Name: EXO-025_Unified-Groups-Hidden-From-GAL.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Pull list of O365 Groups and adjust the hidden from GAL/Outlook attributes on selected ones to $hidden. #>
$Hidden = $false;
$ListGroups = Get-UnifiedGroup | select DisplayName,PrimarySmtpAddress,HiddenFromAddressListsEnabled,HiddenFromExchangeClientsEnabled | Out-GridView -PassThru -Title "Which groups do you want to adjust?";
if ( $null -ne $ListGroups) {
	if ($ListGroups -is [array])
		{
		Write-Host "Adjusting the 'HiddenFromAddressListsEnabled' and 'HiddenFromExchangeClientsEnabled' attributes on the following unified groups...";
		foreach ($li in $ListGroups) {
			Write-Host -NoNewline "Group: "; Write-Host -Fore Yellow $li.PrimarySmtpAddress;
			Set-UnifiedGroup -Identity $li.PrimarySmtpAddress -HiddenFromAddressListsEnabled:$Hidden -HiddenFromExchangeClientsEnabled:$Hidden;
			}
		}
	else {
		Write-Host -NoNewline "Adjusting the 'HiddenFromAddressListsEnabled' and 'HiddenFromExchangeClientsEnabled' attributes on ";
			Write-Host -NoNewline -Fore Yellow $ListGroups.PrimarySmtpAddress; Write-Host ".";
		Set-UnifiedGroup -Identity $ListGroups.PrimarySmtpAddress -HiddenFromAddressListsEnabled:$Hidden -HiddenFromExchangeClientsEnabled:$Hidden;
		}
	}


<# Confirm current Hidden from GAL/Outlook settings of all O365 groups. #>
Get-UnifiedGroup | select DisplayName,PrimarySmtpAddress,HiddenFromAddressListsEnabled,HiddenFromExchangeClientsEnabled | Out-GridView;

<# Set a single O365 group to be hidden from GAL/Outlook. #>
$Group = "o365grouptest@domain.com";
$Hidden = $false;
Set-UnifiedGroup $Group -HiddenFromAddressListsEnabled:$Hidden -HiddenFromExchangeClientsEnabled:$Hidden;

<# Confirm if a single O365 group is set to be hidden from GAL/Outlook? #>
$Group = "o365group@domain.com";
Get-UnifiedGroup $Group | select DisplayName,PrimarySmtpAddress,HiddenFromAddressListsEnabled,HiddenFromExchangeClientsEnabled;
