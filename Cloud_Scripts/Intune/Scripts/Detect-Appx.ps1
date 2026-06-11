<#
.SYNOPSIS
    INT-007 | Intune Proactive Remediation - DETECT: Company Portal (AppX) Presence.

.DESCRIPTION
    Detection script for an Intune Proactive Remediation package.
    Checks whether the Microsoft Company Portal AppX package is installed for all users.

    Exit codes:
        0 = Company Portal found (no remediation required)
        1 = Company Portal not found (remediation required)

    Deploy paired with the corresponding remediation script that installs the package.

.PRODUCT
    Microsoft Intune / Windows / Proactive Remediation

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - No modules required (uses Get-AppxPackage)
    - Deploy via Intune > Devices > Scripts and remediations
    - Pair with a remediation script that installs Microsoft.CompanyPortal

.EXAMPLE
    Run automatically by Intune Proactive Remediation (not called manually)
#>


$appId = "Microsoft.CompanyPortal"
$AppPkgs = Get-AppxPackage -allusers $appId
If ($AppPkgs){
    Write-Output "Found $appId"
    Exit 0
}
else {
    Exit 0
}        
