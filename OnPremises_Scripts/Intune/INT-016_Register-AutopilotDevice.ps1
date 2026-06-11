<#
.SYNOPSIS
    INT-016 | Intune / Autopilot - Register a Device in Windows Autopilot (Hardware Hash Upload).

.DESCRIPTION
    Installs and runs the Get-WindowsAutopilotInfo script to capture the device's
    hardware hash and either:
        - Upload it directly to Intune Autopilot (online mode, default)
        - Export it to a local CSV file (offline mode, with -Csv switch)

    Uses app-only authentication (Client Credentials) to upload directly.

.PRODUCT
    Microsoft Intune / Windows Autopilot

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.PARAMETER Csv
    Switch. If present, exports the hardware hash to .\RegInfo.csv instead of uploading online.

.EXAMPLE
    # Upload hardware hash directly to Intune Autopilot
    .\INT-016_Register-AutopilotDevice.ps1

.EXAMPLE
    # Export hardware hash to CSV (for manual bulk import)
    .\INT-016_Register-AutopilotDevice.ps1 -Csv

.NOTES
    - No pre-installed module required (script auto-installs get-windowsautopilotinfo)
    - Requires NuGet package provider (auto-installed)
    - Run on the target device as Administrator
    - Update $ClientId, $TenantId, $ClientSecret before use
    - The -Online flag uploads directly to your Autopilot tenant
#>

#region ── Parameters ─────────────────────────────────────────────────────────
param(
    [Parameter(Mandatory = $false)]
    [switch]$Csv
)
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Configuration
$ClientId = "05f7e286-a51f-4d4e-b820-da5d3167c3c7"
$TenantId = "0b57e92f-4bfc-4513-81af-dff5bed4c391"
$ClientSecret = "WUo8Q~2wxmApVln5ULJ8H6Y1qd2Dp4Hkn6nIzcdE"

#Install script
Install-PackageProvider -Name NuGet -Confirm:$false -Force:$true
Install-Script get-windowsautopilotinfo -Confirm:$false -Force:$true

# Get hardware hash and upload directly to AP
If($Csv){
    Get-WindowsAutopilotInfo -OutputFile ".\RegInfo.csv"
} else {
    get-windowsautopilotinfo -Online -TenantId $tenantId -AppId $ClientId -AppSecret $ClientSecret
}
#endregion
