<#
.SYNOPSIS
    INT-007 | Intune Proactive Remediation - DETECT: Company Portal (AppX) Presence.

.DESCRIPTION
    Detection script for an Intune Proactive Remediation package.
    Checks whether the Microsoft Company Portal AppX package is installed for all users.

    Exit codes:
        0 = Company Portal found (no remediation required)
        1 = Company Portal not found (remediation required)

.PRODUCT
    Microsoft Intune / Windows / Proactive Remediation

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.2

.NOTES
    - No modules required (uses Get-AppxPackage)
    - Deploy via Intune > Devices > Scripts and remediations

.EXAMPLE
    Run automatically by Intune Proactive Remediation (not called manually)
#>

#region ── Main Program ───────────────────────────────────────────────────────
$appId = "Microsoft.CompanyPortal"
$AppPkgs = Get-AppxPackage -AllUsers $appId

if ($AppPkgs) {
    Write-Output "Found $appId package"
    exit 0
} else {
    Write-Output "$appId package not found"
    exit 1
}
#endregion
