# Sunrise detection script to turn off Windows copilot.
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


