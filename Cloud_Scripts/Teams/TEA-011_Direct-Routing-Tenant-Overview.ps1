<#
.SYNOPSIS
    TEA-011 | Direct Routing Tenant Overview.

.DESCRIPTION
    Export Direct Routing SBC and voice route configuration.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-011 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Teams/Teams%20-%20Direct%20Routing%20Tenant%20Overview.ps1

.NOTES
    Name: TEA-011_Direct-Routing-Tenant-Overview.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to Teams. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module MicrosoftTeams -AllowClobber -Force -Confirm:$false;
Import-Module MicrosoftTeams;
Connect-MicrosoftTeams;
