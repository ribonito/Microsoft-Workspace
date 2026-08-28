<#
.SYNOPSIS
    TEA-016 | Resource Account Troubleshooting.

.DESCRIPTION
    Diagnose Teams resource account and CQ/AA issues.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-016 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Teams/Teams%20-%20Resource%20Account%20Troubleshooting.ps1

.NOTES
    Name: TEA-016_Resource-Account-Troubleshooting.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to Teams. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module MicrosoftTeams -AllowClobber -Force -Confirm:$false;
Import-Module MicrosoftTeams;
Connect-MicrosoftTeams;

<# #>
#Get-CsOnlineUser | Where {$_.InterpretedUserType -match ""} | Select UserPrincipalName,InterpretedUserType,ObjectId;
Get-CsOnlineUser | Where {$_.InterpretedUserType -match "AADConnect"} | Select UserPrincipalName,InterpretedUserType,ObjectId;
Get-CsOnlineUser | Where {$_.InterpretedUserType -match "Hybrid"} | Select UserPrincipalName,InterpretedUserType,ObjectId;
Get-CsOnlineUser | Where {$_.InterpretedUserType -match "Misconfigured"} | Select UserPrincipalName,InterpretedUserType,ObjectId;
