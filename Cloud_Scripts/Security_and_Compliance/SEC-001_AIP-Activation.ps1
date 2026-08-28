<#
.SYNOPSIS
    SEC-001 | AIP Activation.

.DESCRIPTION
    Activate Azure Information Protection unified labeling.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (SEC-001 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Azure%20Information%20Protection/AIP%20-%20Activation.ps1

.NOTES
    Name: SEC-001_AIP-Activation.ps1
    Integrated from O365scripts upstream repository.
#>

<# Previous version using the former AADRM module commands. #>
$LicensingLocation = (Get-AadrmConfiguration).LicensingIntranetDistributionPointUrl
Set-IRMConfiguration -LicensingLocation @{add=$LicensingLocation}
Set-IRMConfiguration -AzureRMSLicensingEnabled $true -InternalLicensingEnabled $true
Set-IRMConfiguration -SimplifiedClientAccessEnabled $true
Set-IRMConfiguration -ClientAccessServerEnabled $true
Get-IRMConfiguration

<# TODO: Updated version. #>
# ...
