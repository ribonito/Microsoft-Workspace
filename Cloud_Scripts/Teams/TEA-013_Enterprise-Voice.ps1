<#
.SYNOPSIS
    TEA-013 | Enterprise Voice.

.DESCRIPTION
    Enterprise Voice policy and user assignment management.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-013 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Teams/Teams%20-%20Enterprise%20Voice.ps1

.NOTES
    Name: TEA-013_Enterprise-Voice.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to Teams. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module MicrosoftTeams -AllowClobber -Force -Confirm:$false;
Import-Module MicrosoftTeams;
Connect-MicrosoftTeams;


<# Toggle EV on a specific user (wait an hour+ in between). #>
$User = "";
Set-CsUser -Identity $User -EnterpriseVoiceEnabled $false;
Set-CsUser -Identity $User -EnterpriseVoiceEnabled $true;


<# Interactive selection of users to enable or disable Enerprise Voice. #>
$ListUsers = Get-CsOnlineUser | Select ObjectId,UserPrincipalName,EnterpriseVoiceEnabled,InterpretedUserTpe | Sort EnterpriseVoiceEnabled,UserPrincipalName |Out-GridView -PassThru;
$ListUsers | % {Write-Host -NoNewLine "Attempting to disable EV on "; Write-Host -Fore Yellow $_.UserPrincipalName; Set-CsUser -Identity $_.ObjectId -EnterpriseVoiceEnabled $false -ErrorAction Continue;}
$ListUsers | % {Write-Host -NoNewLine "Attempting to enable EV on "; Write-Host -Fore Yellow $_.UserPrincipalName; Set-CsUser -Identity $_.ObjectId -EnterpriseVoiceEnabled $true -ErrorAction Continue;}


<# WARNING: Enable or Disable Enterprise Voice for all users. #>
Get-CsOnlineUser | % {Write-Host -NoNewLine "Attempting to enable EV on "; Write-Host -Fore Yellow $_.UserPrincipalName; Set-CsUser -Identity $_.ObjectId -EnterpriseVoiceEnabled $true -ErrorAction Continue;}
Get-CsOnlineUser | % {Write-Host -NoNewLine "Attempting to disable EV on "; Write-Host -Fore Yellow $_.UserPrincipalName; Set-CsUser -Identity $_.ObjectId -EnterpriseVoiceEnabled $false -ErrorAction Continue;}
