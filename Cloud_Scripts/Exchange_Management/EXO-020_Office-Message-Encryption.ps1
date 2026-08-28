<#
.SYNOPSIS
    EXO-020 | Office Message Encryption.

.DESCRIPTION
    Configure and manage OME encryption policies.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-020 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Office%20Message%20Encryption.ps1

.NOTES
    Name: EXO-020_Office-Message-Encryption.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO and AIP. #>
#Install-Module AIPService -AllowClobber -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
Import-Module AIPService;
Import-Module ExchangeOnlineManagement;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;
Connect-AIPService;

<# Connect to EXO and AIP without MFA. #>
#$Creds = Get-Credential -UserName $AdminUpn -Message "Login:";
#Connect-AIPService -Credential $Creds;
#Connect-ExchangeOnline -UserPrincipalName $AdminUpn -Credential $Creds;

<# Confirm which modules are installed? #>
Get-Module AADRM -ListAvailable | Select Name,Version;
Get-Module AIPService -ListAvailable | Select Name,Version;
Get-Module ExchangeOnlineManagement -ListAvailable | Select Name,Version;

<# Remove previous AIP module? #>
#Uninstall-Module AADRM -AllVersions -Force -Confirm:$false;

<# Get AIP status and AIP/IRM configuration. #>
$AipService = Get-AipService;
$AipConfig = Get-AipServiceConfiguration;
$IrmConfig = Get-IRMConfiguration;

<# Display current configuration. #>
Clear;
Write-Host -NoNewLine -Fore Yellow "AIP Service: ";
	if ($AipService -eq "Disabled") {Write-Host -Fore Red $AipService;}
	elseif ($AipService -eq "Enabled") {Write-Host -Fore Green $AipService;}
Write-Host -Fore Yellow "AIP Configuration: "; $AipConfig;
Write-Host -Fore Yellow "IRM Configuration: "; $IrmConfig;

<# Enable AIP if disabled. #>
if ($AipService -eq "Disabled"){
	Write-Host -Fore Yellow "Attempting to enable AIP.";
	Enable-AipService
}


<# If licensing location is empty or does not contain the licensing url taken from the aip service side, add it. #>
$LicenseUrl = ;

$List = $IrmConfig.LicensingLocation;
if (!$List) {Write-Host "Licensing list currently empty."; $List = @()}
if (!$List.Contains($AipConfig.LicensingIntranetDistributionPointUrl)) {
	Write-Host "Adding Licensing Distribution Point URL since it is missing from the list.";
	$List += $AipConfig.LicensingIntranetDistributionPointUrl;
}
Write-Host -Fore Yellow "Setting IRM licensing location list.";
Set-IRMConfiguration -LicensingLocation $List;

Write-Host -Fore Yellow "Enabling Office 365 Message Encryption Azure RMS and Internal Licensing.";
Set-IRMConfiguration -AzureRMSLicensingEnabled $true -InternalLicensingEnabled $true;

<# Enable the Protect button, Encrypt Only and Do Not Forward in OWA #>
Set-IRMConfiguration -SimplifiedClientAccessEnabled $true -SimplifiedClientAccessEncryptOnlyDisabled $false -SimplifiedClientAccessDoNotForwardDisabled $false -EnablePdfEncryption $true;


Set-IRMConfiguration -SearchEnabled $true;

<# Confirm? #>

Get-IRMConfiguration;
Get-RMSTemplate;
Test-IRMConfiguration -Sender $AdminUpn;


<# Optional: Disable OME Clear OME v1 TPDs +v2? #>
Write-Host -Fore Yellow "Disabling OME v1 and v2 and re-enabling OME v2 only.";
Set-IRMConfiguration -AzureRMSLicensingEnabled $false -InternalLicensingEnabled $false -RMSOnlineKeySharingLocation $null -Force -Confirm:$false;
Set-IRMConfiguration -AzureRMSLicensingEnabled $true -InternalLicensingEnabled $true;
