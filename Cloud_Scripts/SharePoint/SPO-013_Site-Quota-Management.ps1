<#
.SYNOPSIS
    SPO-013 | Site Quota Management.

.DESCRIPTION
    View and set SharePoint site storage quotas.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (SPO-013 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/SharePoint%20Online/SPO%20-%20Site%20Quota.ps1

.NOTES
    Name: SPO-013_Site-Quota-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Set storage quota on an ODFB site. #>
$SiteOD = "user_domain_com";
$SiteQuota = 5 * 1048576; 
$SiteQuotaWarn = 4.75 * 1048576;
Set-SPOSite -Identity "https://${tenant}-my.sharepoint.com/personal/${site_od4b}" -StorageQuota $SiteQuota -StorageQuotaWarningLevel $SiteQuotaWarn;
Get-SPOSite -Identity "https://${tenant}-my.sharepoint.com/personal/${site_od4b}" | select StorageQuota*;
