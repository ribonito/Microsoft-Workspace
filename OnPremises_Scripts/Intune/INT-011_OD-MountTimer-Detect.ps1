<#
.SYNOPSIS
    INT-011 | Intune Proactive Remediation - DETECT: OneDrive Timer Automount Registry Setting.

.DESCRIPTION
    Detection script for an Intune Proactive Remediation package.
    Verifies that the OneDrive Business1 account TimerAutomount registry value is set to 1 (enabled).

    Registry key checked:
        HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1
        Value: Timerautomount = 1 (QWORD)

    Exit codes:
        0 = Value is correctly set (no remediation needed)
        1 = Value is missing or incorrect (remediation required)

    Deploy paired with INT-012 (OD-MountTimer-remediate.ps1).

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

Try {
    $Registry = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop | Select-Object -ExpandProperty $Name
    If ($Registry -eq $Value){
        Write-Output "Timer Automount Set to one"
        Exit 0
    } 
    Write-Warning "Timer Automount Not configured to one"
    Exit 1
} 
Catch {
    Write-Warning "Another Issue Occured"
    Exit 1
}
#endregion