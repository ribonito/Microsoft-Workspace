    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Action = "Install",
        [Parameter(Mandatory = $true)]
        [string]$id,
        [Parameter(Mandatory = $false)]
        [string]$Scope = "machine",
        [Parameter(Mandatory = $false)]
        [string]$Source = "msstore",
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
    }
    Catch {
        Throw "Failed to start $PSCOMMANDPATH"
    }
    Exit
}

$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$Name-$Action.log"
$WingetVersionFile = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\winget-version.txt"
$WingetSourceUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$MinWingetVersion = "v1.8.1791"

# Start transcript logging
Start-Transcript -Path $LogPath -Force
$CurrentDir = Get-Location

## Find winget-cli
### Find directory
$WingetDirectory = [string](
    $(
        if ([System.Security.Principal.WindowsIdentity]::GetCurrent().'User'.'Value' -eq 'S-1-5-18') {
            (Get-Item -Path ('{0}\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe' -f $env:ProgramW6432)).'FullName' | Select-Object -First 1
        }
        else {
            '{0}\Microsoft\WindowsApps' -f $env:LOCALAPPDATA
        }
    )
)
### Find file name
$WingetCliFileName = [string](
    $(
        [string[]](
            'AppInstallerCLI.exe',
            'winget.exe'
        )
    ).Where{
        [System.IO.File]::Exists(
            ('{0}\{1}' -f $WingetDirectory, $_)
        )
    } | Select-Object -First 1
)
# Combine and file name
$WingetCliPath = [string] '{0}\{1}' -f $WingetDirectory, $WingetCliFileName


# Check if $WingetCli exists, exit 1 if not
if (-not [System.IO.File]::Exists($WingetCliPath)) {
    Write-Error "Did not find Winget in $WingetCliPath."
    Exit 3
} else {
    Write-Output "Using Winget client in $WingetCliPath"
}

#Cleanup the version file
if (Test-Path $WingetVersionFile) {
        $null = Remove-Item -Path $WingetVersionFile -Force
}
#Check version of winget
$process = Start-Process -FilePath "$WingetCliPath" -ArgumentList "--version" -PassThru -Wait -ErrorAction STOP -RedirectStandardOutput "$WingetVersionFile" -NoNewWindow
if ($process.ExitCode -ne 0) {
    Write-Error "Checking Winget version failed with exit code $($process.ExitCode). Installation will continue."
}
if (Test-Path $WingetVersionFile) {
    $WingetVersion = $(Get-Content -LiteralPath $WingetVersionFile -Raw).ToString()
}

# Try to upgrade winget if too old
If($WingetVersion){
    $WingetVersion = [string]::join("",($WingetVersion.Split("`n")))
    Write-Output "Installed Winget version : $WingetVersion"
    if($WingetVersion -le $MinWingetVersion){
        Write-Output "Installed Winget version : $WingetVersion is less than required minimum version $MinWingetVersion. Attemtping an upgrade of Winget."
        try {
            Add-AppxPackage -Path $WingetSourceUrl -ForceApplicationShutdown
        } catch {
            Write-Error $_.Exception.Message
            Stop-Transcript
            Exit 3
        } 
    } else {
        Write-Output "Installed Winget version : $WingetVersion is same or higher than required minimum version $MinWingetVersion. Upgrade is not required."
    }
}   

if($Action -eq "install"){
    Write-Output "Install $Name"
    $Arguments = "install --id $id --source $Source --scope $scope --silent --accept-source-agreements --accept-package-agreements --log ""$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$Name-winget.log"""
} else {
    Write-Output "Uninstall $Name"
    $Arguments = "uninstall --id $id --source $Source --silent --accept-source-agreements --log ""$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$Name-winget.log"""
}
    Write-Output $Arguments
try {
    $process = Start-Process -FilePath "$WingetCliPath" -ArgumentList $Arguments -PassThru -Wait -ErrorAction STOP

    if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3010 -and $process.ExitCode -ne -1978335189) {
        Write-Error "$Action action failed with exit code $($process.ExitCode)."
        Stop-Transcript
        Exit 3
    } else {
        Write-Output "$Action action completed with exit code $($process.ExitCode)."
    }
}
catch {
   Write-Error $_.Exception.Message
   Stop-Transcript
   Exit 3
}

# Stop transcript logging
Stop-Transcript