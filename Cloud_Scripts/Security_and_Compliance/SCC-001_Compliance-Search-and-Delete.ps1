<#
.SYNOPSIS
    SCC-001 | Compliance Search and Delete.

.DESCRIPTION
    Create compliance searches and purge matching content.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (SCC-001 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Security%20&%20Compliance/S&C%20-%20Search%20and%20Delete.ps1

.NOTES
    Name: SCC-001_Compliance-Search-and-Delete.ps1
    Integrated from O365scripts upstream repository.
#>

<# Start by creating the content search query using the interface or by using New-ComplianceSearch. #>
#ew-ComplianceSearch;

<# Purge or delete items? #>
$purge_type = "SoftDelete vs HardDelete";
#$purge_type = "SoftDelete", "HardDelete" | Out-GridView -OutputMode Single -PassThru;

<# Specify the search name manually vs interactively? #>
$search_name = "Test Search";
$search_name = Get-ComplianceSearch | Out-GridView -Title "Which compliance search do you want to use?" -PassThru;

<# Warning: Remove items based on the specified content search query and delete/purge up to 10 items per mailbox per pass. #>
New-ComplianceSearchAction -SearchName $search_name -Purge -PurgeType $purge_type -Confirm:$false;

<# Remove the search action so it can be started to delete more result items. #>
$purge_name = "${search_name}_Purge";
Remove-ComplianceSearchAction $purge_name -Confirm:$false

<# Verify search action has been removed. #>
Get-ComplianceSearchAction $purge_name;
