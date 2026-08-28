<#
.SYNOPSIS
    EXO-021 | Organization Management.

.DESCRIPTION
    View and modify Exchange Online organization settings.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-021 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Organization%20Management.ps1

.NOTES
    Name: EXO-021_Organization-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Hydrate tenant, one time only. #>
Enable-OrganizationCustomization;

<# Enable auto-expanding archiving for your entire organization. #>
Set-OrganizationConfig -AutoExpandingArchive;

<# Verify current organization configuration. #>
Get-OrganizationConfig;