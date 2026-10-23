<#
.SYNOPSIS
    Manages local OneDrive for Business client registry policies and configuration toggles.

.DESCRIPTION
    Configures client-side Windows registry settings for the OneDrive sync application (onedrive.exe).
    Controls policies including disabling personal accounts sync, enforcing Files On-Demand,
    suppressing post-setup tutorials, and managing silent account configuration.

.PARAMETER Policy
    Target policy setting: 'DisablePersonalSync', 'FilesOnDemandEnabled', 'DisableTutorial', 'DisableFileSyncNGSC', or 'Audit'.

.PARAMETER Value
    Integer DWORD value (1 to enable policy, 0 to disable). Defaults to 1.

.NOTES
    Requires administrative permissions to modify HKLM registry paths.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\OneDrive Client Management.ps1 -Policy "DisablePersonalSync" -Value 1
    Blocks users from syncing personal consumer OneDrive accounts on the local workstation.

.LINK
    https://learn.microsoft.com/onedrive/use-group-policy
    https://learn.microsoft.com/onedrive/deploy-on-windows
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("DisablePersonalSync", "FilesOnDemandEnabled", "DisableTutorial", "DisableFileSyncNGSC", "Audit")]
    [string]$Policy = "Audit",

    [Parameter(Mandatory = $false)]
    [int]$Value = 1
)

$regPath = "HKLM:\Software\Microsoft\Windows\OneDrive"

# Ensure target registry key exists
if (-not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}

if ($Policy -ne "Audit") {
    Write-Host "Configuring OneDrive client policy '$Policy' = $Value in $regPath..." -ForegroundColor Cyan
    New-ItemProperty -Path $regPath -Name $Policy -Value $Value -PropertyType DWORD -Force | Out-Null
    Write-Host "Policy updated successfully." -ForegroundColor Green
}

# Display current configuration
Write-Host "`n=== Current OneDrive Client Machine Policies ($regPath) ===" -ForegroundColor Yellow
$props = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
if ($props) {
    $props | Select-Object -Property * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSDrive, PSProvider | Format-List
} else {
    Write-Host "No policies currently configured." -ForegroundColor Gray
}
