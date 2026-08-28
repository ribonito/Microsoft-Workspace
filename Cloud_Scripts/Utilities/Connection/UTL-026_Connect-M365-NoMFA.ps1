<#
.SYNOPSIS
    UTL-026 | Connect M365 No MFA.

.DESCRIPTION
    Connect to M365 services without MFA prompt.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-026 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Tools/Connect-M365NoMFA.ps1

.NOTES
    Name: UTL-026_Connect-M365-NoMFA.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connection options. #>
$AdminUpn = "admin@domain.com";
$Tenant = "contoso";
$Creds = Get-Credential -Message "Login" -UserName $AdminUpn;

<# Connect to MSOL. #>
Import-Module MSOnline;
Connect-MsolService -Credential $Creds;

<# Connect to AAD. #>
Import-Module AzureAD;
Connect-AzureAD -AccountId $AdminUpn -Credential $Creds;

<# Connect to EXO or S&C. #>
Import-Module ExchangeOnlineManagement;
Connect-ExchangeOnline -UserPrincipalName $AdminUpn -Credential $Creds;
#Connect-IPPSSession -UserPrincipalName $AdminUpn -Credential $Creds;

<# Connect to SFB. #>
Import-Module MicrosoftTeams -RequiredVersion 1.1.6;
$Session_Sfb = New-CsOnlineSession -Credentials $Creds;
Import-PSSession $Session_Sfb;

<# Connect to SPO. #>
Import-Module Microsoft.Online.SharePoint.PowerShell;
Connect-SPOService -Url "https://$Tenant-admin.sharepoint.com" -Credential $Creds;

<# Connect to SPO PnP. #>
Import-Module PnP.PowerShell;
Connect-PnPOnline -Url "https://${Tenant}-my.sharepoint.com" -Interactive;
