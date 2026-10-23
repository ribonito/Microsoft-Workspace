<#
.SYNOPSIS
    Manages Microsoft Teams meeting cloud recording policies and storage locations.

.DESCRIPTION
    Configures and reviews Teams meeting recording policies across the tenant. Allows administrators
    to specify recording storage targets (OneDrive for Business / SharePoint vs legacy Stream),
    manage recording permissions, and control geographic storage policy settings.

.NOTES
    Requires MicrosoftTeams PowerShell module (v2+).
    Author: Josep Canas - M365 Solutions Architect
    Product: Microsoft Teams Administration

.EXAMPLE
    .\Teams - Cloud Recording Management.ps1
    Applies cloud recording policies to the Global meeting policy and verifies configuration.

.LINK
    https://learn.microsoft.com/powershell/module/skype/set-csteamsmeetingpolicy
    https://learn.microsoft.com/microsoftteams/cloud-recording
#>

[CmdletBinding()]
param ()

# Step 1: Connect to Microsoft Teams
Import-Module MicrosoftTeams -ErrorAction SilentlyContinue
Connect-MicrosoftTeams

# Step 2: Configure Global Meeting Policy for modern OneDrive/SharePoint storage
Write-Host "Configuring Teams cloud recording storage to OneDrive for Business / SharePoint..." -ForegroundColor Cyan
Set-CsTeamsMeetingPolicy -Identity "Global" -RecordingStorageMode "OneDriveForBusiness" -AllowCloudRecording $true

# Step 3: Optional configuration - Allow cross-region recording storage (if permitted by governance)
# Set-CsTeamsMeetingPolicy -Identity "Global" -AllowRecordingStorageOutsideRegion $true

# Step 4: Validate Global policy configuration
Write-Host "`n=== Global Meeting Policy Cloud Recording Settings ===" -ForegroundColor Green
Get-CsTeamsMeetingPolicy -Identity "Global" |
    Select-Object Identity, AllowCloudRecording, RecordingStorageMode, AllowRecordingStorageOutsideRegion |
    Format-List

# Step 5: Enumerate all meeting policies in tenant
Write-Host "`nAll Teams Meeting Policies in Tenant:" -ForegroundColor Cyan
Get-CsTeamsMeetingPolicy | Format-Table Identity, AllowCloudRecording, RecordingStorageMode -AutoSize