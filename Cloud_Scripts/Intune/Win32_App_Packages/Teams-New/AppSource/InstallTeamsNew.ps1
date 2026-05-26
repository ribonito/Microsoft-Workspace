function Log() {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$false)] [String] $message
	)

	$ts = get-date -f "yyyy/MM/dd hh:mm:ss tt"
	Write-Output "$ts $message"
}

# Function to uninstall Teams Classic
function Uninstall-TeamsClassic($TeamsPath) {
    try {
        $process = Start-Process -FilePath "$TeamsPath\Update.exe" -ArgumentList "--uninstall /s" -PassThru -Wait -ErrorAction STOP

        if ($process.ExitCode -ne 0) {
            Write-Error "Uninstallation failed with exit code $($process.ExitCode)."
        }
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

$PackageName = "MicrosoftTeamsNEW"
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$PackageName-install.log"

# Start transcript logging
Start-Transcript -Path $LogPath -Force

#Remove consumer version of Teams
Log "Removing consumer Teams"
Get-AppxPackage MicrosoftTeams* | Remove-AppxPackage

#Removing Classic Teams Machine-wide Installer
Log "Removing Classic Teams Machine-wide Installer"
$registryPath = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$MachineWide = Get-ItemProperty -Path $registryPath | Where-Object -Property DisplayName -eq "Teams Machine-Wide Installer"
if ($MachineWide) {
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/x ""$($MachineWide.PSChildName)"" /qn" -NoNewWindow -Wait
}
else {
    Log "Teams Machine-Wide Installer not found"
}

$AllUsers = Get-ChildItem -Path "$($ENV:SystemDrive)\Users"
foreach ($User in $AllUsers) {
    Log "Processing user: $($User.Name)"
    # Locate installation folder
    $localAppData = "$($ENV:SystemDrive)\Users\$($User.Name)\AppData\Local\Microsoft\Teams"
    $programData = "$($env:ProgramData)\$($User.Name)\Microsoft\Teams"
    if (Test-Path "$localAppData\Current\Teams.exe") {
        Log "  Uninstall Teams for user $($User.Name)"
        Uninstall-TeamsClassic -TeamsPath $localAppData
    }
    elseif (Test-Path "$programData\Current\Teams.exe") {
        Logt "  Uninstall Teams for user $($User.Name)"
        Uninstall-TeamsClassic -TeamsPath $programData
    }
    else {
        Log "  Teams installation not found for user $($User.Name)"
    }
}

# Remove old Teams folders and icons
$TeamsFolder_old = "$($ENV:SystemDrive)\Users\*\AppData\Local\Microsoft\Teams"
$TeamsIcon_old = "$($ENV:SystemDrive)\Users\*\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Microsoft Teams*.lnk"
Get-Item $TeamsFolder_old | Remove-Item -Force -Recurse
Get-Item $TeamsIcon_old | Remove-Item -Force -Recurse

# New Teams installation
Log "Installing new Teams"
$currentDirectory = Split-Path -Parent $PSCommandPath
$exePath = Join-Path -Path $currentDirectory -ChildPath "teamsbootstrapper.exe"
Start-Process -FilePath $exePath -ArgumentList "-p" -NoNewWindow -Wait

# Stop transcript logging
Stop-Transcript