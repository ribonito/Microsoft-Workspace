<#
.SYNOPSIS
    INT-012 | Intune Proactive Remediation - REMEDIATE: Set OneDrive Timer Automount Registry Value.

.DESCRIPTION
    Remediation script for an Intune Proactive Remediation package.
    Sets the OneDrive Business1 account TimerAutomount registry value to 1.

    Registry key written:
        HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1
        Value: Timerautomount = 1 (QWORD)

    Deploy paired with INT-011 (OD-MountTimer-detect.ps1).

.PRODUCT
    Microsoft Intune / OneDrive for Business / Proactive Remediation

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - No modules required
    - Runs in user context (HKCU)
    - Deploy via Intune > Devices > Scripts and remediations

.EXAMPLE
    Run automatically by Intune Proactive Remediation (not called manually)
#>

#region ── Main Program ───────────────────────────────────────────────────────
$Path = "HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1"
$Name = "Timerautomount"
$Type = "QWORD"
$Value = 1

Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 
#endregion