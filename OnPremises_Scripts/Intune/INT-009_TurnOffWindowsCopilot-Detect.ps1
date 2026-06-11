<#
.SYNOPSIS
    INT-009 | Intune Proactive Remediation - DETECT: Turn Off Windows Copilot (All User Profiles).

.DESCRIPTION
    Detection script for an Intune Proactive Remediation package.
    Checks all local user registry hives (HKU) to verify that the Windows Copilot
    policy is set to disabled (TurnOffWindowsCopilot = 1) for each user profile.

    Registry key checked (per user):
        HKU\<SID>\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot
        Value: TurnOffWindowsCopilot = 1 (DWORD)

    Workaround for: Settings Catalog error 65000 on Windows with M365 Business Premium license.

    Exit codes:
        0 = All profiles have Copilot disabled (no remediation needed)
        1 = At least one profile has Copilot enabled (remediation required)

    Deploy paired with INT-010 (TurnOffWindowsCopilot-remediate.ps1).

.PRODUCT
    Microsoft Intune / Windows / Proactive Remediation

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - No modules required
    - Handles both 32-bit and 64-bit process architecture (PROCESSOR_ARCHITEW6432 check)
    - Deploy via Intune > Devices > Scripts and remediations

.EXAMPLE
    Run automatically by Intune Proactive Remediation (not called manually)
#>

#region ── Main Program ───────────────────────────────────────────────────────
If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
    }
    Catch {
        Throw "Failed to start $PSCOMMANDPATH"
    }
    Exit
}

New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-null
$RegRoot = "HKU:\"
$RegPath = "SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
$RegValueName = "TurnOffWindowsCopilot"
$RegValue = 1

# Get all user profiles
$UserProfiles = Get-ChildItem -Path $RegRoot

# get reg values from each profile
foreach ($profile in $UserProfiles) {
    if(-not($profile.Name -match "_Classes") -and ($profile.Name -match "S-1-5-21" -or $profile.Name -match ".DEFAULT" -or $profile.Name -match "S-1-12")){
        $FullRegPath = "$RegRoot$($profile.pschildName)\$RegPath"
        $Val = Get-ItemProperty -Path $FullRegPath -Name $RegValueName -ErrorAction SilentlyContinue
        if($Val.$RegValueName -ne $RegValue){
            $remediation = $true
        }
    }
}

if($remediation){
    Exit 1
} else {
    Write-Host "Remediation is not required."
    Exit 0
}
#endregion
