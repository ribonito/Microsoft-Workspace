<#
.SYNOPSIS
    INT-013 | Intune Proactive Remediation - DETECT: Hybrid AD Joined Device Rename Completion.

.DESCRIPTION
    Detection script for an Intune Proactive Remediation package.
    Checks if the device has already been renamed per its Autopilot record by verifying
    a registry tag written after a successful rename.

    Registry key checked:
        HKLM:\Software\Sunrise\Manage
        Value: HAADJComputerRename = 1 (DWORD)

    Exit codes:
        0 = Tag found — rename completed or not required (no remediation)
        1 = Tag NOT found — rename still needs to be performed (remediation required)

    Deploy paired with INT-014 (HybridCompuerRename-remediate.ps1).

.PRODUCT
    Microsoft Intune / Windows Autopilot / Hybrid AD Join / Proactive Remediation

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - No modules required
    - Device name is sourced from the Windows Autopilot record (set via INT-003)
    - Deploy via Intune > Devices > Scripts and remediations

.EXAMPLE
    Run automatically by Intune Proactive Remediation (not called manually)
#>

# Detection script for rename hybrid joined device operation
# device name stored in the computer autopilot record is used to set the name of the device

if (Test-Path "HKLM:/Software/Sunrise/Manage") {
    $subKey = Get-Item "HKLM:/Software/Sunrise/Manage"
    $Value = $SubKey.GetValue("HAADJComputerRename")
    if ($Value -eq 1) {
        Write-Host "Found registry value HKLM:/Software/Sunrise/Manage/HAADJComputerRename=1. Computer rename has been completed or not required."            
        exit 0
    }
}
exit 1
