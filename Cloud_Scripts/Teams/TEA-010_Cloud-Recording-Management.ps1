<#
.SYNOPSIS
    TEA-010 | Cloud Recording Management.

.DESCRIPTION
    Manage Teams cloud meeting recording policies.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-010 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Teams/Teams%20-%20Cloud%20Recording%20Management.ps1

.NOTES
    Name: TEA-010_Cloud-Recording-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to Teams. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module MicrosoftTeams -AllowClobber -Force -Confirm:$false;
Import-Module MicrosoftTeams;
Connect-MicrosoftTeams;

<# Use OneDrive for Business and SharePoint or Stream for meeting recordings. #>
Set-CsTeamsMeetingPolicy -Identity "Global" -RecordingStorageMode "OneDriveForBusiness";

<# Opt out of OneDrive for Business and SharePoint to continue using Stream. #>
Set-CsTeamsMeetingPolicy -Identity "Global" -RecordingStorageMode "Stream";

<# Allow storing recording outside of region. Note that all meeting recordings will be permanently stored in another region, and can't be migrated. #>
Set-CsTeamsMeetingPolicy -Identity "Global" -AllowCloudRecording $true -AllowRecordingStorageOutsideRegion $true;

<# Confirm global meeting policy configuration. #>
Get-CsTeamsMeetingPolicy -Identity "Global";

<# Confirm all meeting policies. #>
Get-CsTeamsMeetingPolicy | Format-List;