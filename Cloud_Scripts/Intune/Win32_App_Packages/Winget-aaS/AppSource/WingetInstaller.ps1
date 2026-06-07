# Sunrise Winget installation wrapper script

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Action = "Install",
        [Parameter(Mandatory = $true)]
        [string]$id,
        [Parameter(Mandatory = $false)]
        [string]$Scope,
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

$WapperVersion = "1.1"
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$Name-$Action.log"
$WingetVersionFile = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\winget-version.txt"
$MinWingetVersion = "2024.627.1939.0"

# Start transcript logging
Start-Transcript -Path $LogPath -Force
$CurrentDir = Get-Location
Write-Output "Wrapper script version: $WapperVersion"

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

#Check version of winget
try {
    $TestWinget = Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq "Microsoft.DesktopAppInstaller"}
    # Try to upgrade winget if too old
    $WingetVersion = [Version]$TestWinGet.Version
    Write-Output "Installed Winget version : $WingetVersion"
    if($WingetVersion -lt [Version]$MinWingetVersion){
        Write-Output "Installed Winget version : $WingetVersion is less than required minimum version $MinWingetVersion. Attemtping an upgrade of Winget."

		#Download WinGet MSIXBundle
		Write-Host "Not installed. Downloading WinGet..." 
		$WinGetURL = "https://aka.ms/getwinget"
	    $dc = New-Object net.webclient
        $dc.UseDefaultCredentials = $true
        $dc.Headers.Add("user-agent", "Inter Explorer")
        $dc.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
	    $dc.DownloadFile($WinGetURL, "$env:temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle")
		
		#Install WinGet MSIXBundle 
        Write-Host "Installing MSIXBundle for App Installer..." 
		Add-AppxProvisionedPackage -Online -PackagePath "$env:temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -SkipLicense 
		Write-Host "Installed MSIXBundle for App Installer" -ForegroundColor Green
		#Remove WinGet MSIXBundle 
		Remove-Item -Path "$env:temp\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -Force -ErrorAction Continue
    } else {
        Write-Output "Installed Winget version : $WingetVersion is same or higher than required minimum version $MinWingetVersion. Upgrade is not required."
    }
} catch {
   Write-Error $_.Exception.Message
   Write-Warning "Checking Winget version failed, but Installation will continue."   Stop-Transcript
}

# Installing / uninststalling the application package
if($Action -eq "install"){
    Write-Output "Install $Name"
    $Arguments = "install --id $id --scope $scope --silent --accept-source-agreements --accept-package-agreements --log ""$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$Name-winget.log"""
} else {
    Write-Output "Uninstall $Name"
    $Arguments = "uninstall --id $id --silent --accept-source-agreements --log ""$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$Name-winget.log"""
}
if($Scope){$Arguments += " --source $Source" }

    Write-Output $Arguments
try {
    $process = Start-Process -FilePath "$WingetCliPath" -ArgumentList $Arguments -PassThru -Wait -ErrorAction STOP

    if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3010 -and $process.ExitCode -ne -1978335189) {
        Write-Error "$Action action failed with exit code $($process.ExitCode)."
        Stop-Transcript
        Exit 3
    } else {
        Write-Output "$Action action completed with exit code $($process.ExitCode)."
        #Set a tag in the registry to avoid further name checks in future
        REG add "HKLM\Software\Sunrise\Manage\Winget" /v "$id" /t REG_DWORD /d 1 /f
    }
}
catch {
   Write-Error $_.Exception.Message
   Stop-Transcript
   Exit 3
}

# Stop transcript logging
Stop-Transcript