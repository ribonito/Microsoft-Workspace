<#
.SYNOPSIS
    EXO-023 | Tenant Hydration.

.DESCRIPTION
    Check and trigger Exchange Online tenant hydration status.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-023 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Tenant%20Hydration.ps1

.NOTES
    Name: EXO-023_Tenant-Hydration.ps1
    Integrated from O365scripts upstream repository.
#>

<# QUICKRUN: Install and Connect to EXO v2. #>
$Me = "admin@tenantname.onmicrosoft.com";
Set-ExecutionPolicy RemoteSigned;
Install-Module ExchangeOnlineManagement -Confirm:$false;
Import-Module ExchangeOnlineManagement;
Connect-ExchangeOnline -UserPrincipalName $me;

<# Force hydration of the tenant. #>
Enable-OrganizationCustomization

<# Confirm? #>
Get-OrganizationConfig | fl Name,isDehydrated
