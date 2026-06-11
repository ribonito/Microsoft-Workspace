<#
.SYNOPSIS
    INT-010 | Intune Proactive Remediation - REMEDIATE: Turn Off Windows Copilot (All User Profiles).

.DESCRIPTION
    Remediation script for an Intune Proactive Remediation package.
    Sets the Windows Copilot registry policy to disabled for every local user profile.

    Registry key written (per user):
        HKU\<SID>\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot
        Value: TurnOffWindowsCopilot = 1 (DWORD)

    Creates the registry path if it does not exist.
    Workaround for: Settings Catalog error 65000 on Windows with M365 Business Premium license.

    Exit codes:
        0 = All profiles successfully updated
        1 = Failed to write registry key for one or more profiles

    Deploy paired with INT-009 (TurnOffWindowsCopilot-detect.ps1).

.PRODUCT
    Microsoft Intune / Windows / Proactive Remediation

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - No modules required
    - Handles both 32-bit and 64-bit process architecture
    - Deploy via Intune > Devices > Scripts and remediations

.EXAMPLE
    Run automatically by Intune Proactive Remediation (not called manually)
#>

# Remediation script to turn off Windows Copilot for all user profiles
# Workaround for Settings Catalog error 65000 on Windows with M365 Business Premium license

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
            try {
                if (-not (Test-Path "$FullRegPath")) {
                    $null = New-Item -Path "$FullRegPath" -Force
                }
                New-ItemProperty -Path $FullRegPath -Name $RegValueName -Type DWORD -Value $RegValue -Force
            } catch {
                Write-Error $_
                Exit 1
            }
        }
    }
}

Exit 0


