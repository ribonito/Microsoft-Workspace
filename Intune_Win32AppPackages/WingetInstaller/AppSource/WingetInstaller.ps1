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

$WapperVersion = "1.2"
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$Name-$Action.log"
$WingetVersionFile = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\winget-version.txt"
$MinWingetVersion = "2024.627.1939.0"


function Get-WingetReturnCodeDescription {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Decimal
    )
    switch ($Decimal) {
        0 {
            return 'Command completed successfully'
        }
        -1978335231 {
            return 'Internal Error'
        }
        -1978335230 {
            return 'Invalid command line arguments'
        }
        -1978335229 {
            return 'Executing command failed'
        }
        -1978335228 {
            return 'Opening manifest failed'
        }
        -1978335227 {
            return 'Cancellation signal received'
        }
        -1978335226 {
            return 'Running ShellExecute failed'
        }
        -1978335225 {
            return 'Cannot process manifest. The manifest version is higher than supported. Please update the client.'
        }
        -1978335224 {
            return 'Downloading installer failed'
        }
        -1978335223 {
            return 'Cannot write to index; it is a higher schema version'
        }
        -1978335222 {
            return 'The index is corrupt'
        }
        -1978335221 {
            return 'The configured source information is corrupt'
        }
        -1978335220 {
            return 'The source name is already configured'
        }
        -1978335219 {
            return 'The source type is invalid'
        }
        -1978335218 {
            return 'The MSIX file is a bundle, not a package'
        }
        -1978335217 {
            return 'Data required by the source is missing'
        }
        -1978335216 {
            return 'None of the installers are applicable for the current system'
        }
        -1978335215 {
            return 'The installer file''s hash does not match the manifest'
        }
        -1978335214 {
            return 'The source name does not exist'
        }
        -1978335213 {
            return 'The source location is already configured under another name'
        }
        -1978335212 {
            return 'No packages found'
        }
        -1978335211 {
            return 'No sources are configured'
        }
        -1978335210 {
            return 'Multiple packages found matching the criteria'
        }
        -1978335209 {
            return 'No manifest found matching the criteria'
        }
        -1978335208 {
            return 'Failed to get Public folder from source package'
        }
        -1978335207 {
            return 'Command requires administrator privileges to run'
        }
        -1978335206 {
            return 'The source location is not secure'
        }
        -1978335205 {
            return 'The Microsoft Store client is blocked by policy'
        }
        -1978335204 {
            return 'The Microsoft Store app is blocked by policy'
        }
        -1978335203 {
            return 'The feature is currently under development. It can be enabled using winget settings.'
        }
        -1978335202 {
            return 'Failed to install the Microsoft Store app'
        }
        -1978335201 {
            return 'Failed to perform auto complete'
        }
        -1978335200 {
            return 'Failed to initialize YAML parser'
        }
        -1978335199 {
            return 'Encountered an invalid YAML key'
        }
        -1978335198 {
            return 'Encountered a duplicate YAML key'
        }
        -1978335197 {
            return 'Invalid YAML operation'
        }
        -1978335196 {
            return 'Failed to build YAML doc'
        }
        -1978335195 {
            return 'Invalid YAML emitter state'
        }
        -1978335194 {
            return 'Invalid YAML data'
        }
        -1978335193 {
            return 'LibYAML error'
        }
        -1978335192 {
            return 'Manifest validation succeeded with warning'
        }
        -1978335191 {
            return 'Manifest validation failed'
        }
        -1978335190 {
            return 'Manifest is invalid'
        }
        -1978335189 {
            return 'No applicable update found'
        }
        -1978335188 {
            return 'winget upgrade --all completed with failures'
        }
        -1978335187 {
            return 'Installer failed security check'
        }
        -1978335186 {
            return 'Download size does not match expected content length'
        }
        -1978335185 {
            return 'Uninstall command not found'
        }
        -1978335184 {
            return 'Running uninstall command failed'
        }
        -1978335183 {
            return 'ICU break iterator error'
        }
        -1978335182 {
            return 'ICU casemap error'
        }
        -1978335181 {
            return 'ICU regex error'
        }
        -1978335180 {
            return 'Failed to install one or more imported packages'
        }
        -1978335179 {
            return 'Could not find one or more requested packages'
        }
        -1978335178 {
            return 'Json file is invalid'
        }
        -1978335177 {
            return 'The source location is not remote'
        }
        -1978335176 {
            return 'The configured rest source is not supported'
        }
        -1978335175 {
            return 'Invalid data returned by rest source'
        }
        -1978335174 {
            return 'Operation is blocked by Group Policy'
        }
        -1978335173 {
            return 'Rest source internal error'
        }
        -1978335172 {
            return 'Invalid rest source url'
        }
        -1978335171 {
            return 'Unsupported MIME type returned by rest source'
        }
        -1978335170 {
            return 'Invalid rest source contract version'
        }
        -1978335169 {
            return 'The source data is corrupted or tampered'
        }
        -1978335168 {
            return 'Error reading from the stream'
        }
        -1978335167 {
            return 'Package agreements were not agreed to'
        }
        -1978335166 {
            return 'Error reading input in prompt'
        }
        -1978335165 {
            return 'The search request is not supported by one or more sources'
        }
        -1978335164 {
            return 'The rest source endpoint is not found.'
        }
        -1978335163 {
            return 'Failed to open the source.'
        }
        -1978335162 {
            return 'Source agreements were not agreed to'
        }
        -1978335161 {
            return 'Header size exceeds the allowable limit of 1024 characters. Please reduce the size and try again.'
        }
        -1978335160 {
            return 'Missing resource file'
        }
        -1978335159 {
            return 'Running MSI install failed'
        }
        -1978335158 {
            return 'Arguments for msiexec are invalid'
        }
        -1978335157 {
            return 'Failed to open one or more sources'
        }
        -1978335156 {
            return 'Failed to validate dependencies'
        }
        -1978335155 {
            return 'One or more package is missing'
        }
        -1978335154 {
            return 'Invalid table column'
        }
        -1978335153 {
            return 'The upgrade version is not newer than the installed version'
        }
        -1978335152 {
            return 'Upgrade version is unknown and override is not specified'
        }
        -1978335151 {
            return 'ICU conversion error'
        }
        -1978335150 {
            return 'Failed to install portable package'
        }
        -1978335149 {
            return 'Volume does not support reparse points.'
        }
        -1978335148 {
            return 'Portable package from a different source already exists.'
        }
        -1978335147 {
            return 'Unable to create symlink, path points to a directory.'
        }
        -1978335146 {
            return 'The installer cannot be run from an administrator context.'
        }
        -1978335145 {
            return 'Failed to uninstall portable package'
        }
        -1978335144 {
            return 'Failed to validate DisplayVersion values against index.'
        }
        -1978335143 {
            return 'One or more arguments are not supported.'
        }
        -1978335142 {
            return 'Embedded null characters are disallowed for SQLite'
        }
        -1978335141 {
            return 'Failed to find the nested installer in the archive.'
        }
        -1978335140 {
            return 'Failed to extract archive.'
        }
        -1978335139 {
            return 'Invalid relative file path to nested installer provided.'
        }
        -1978335138 {
            return 'The server certificate did not match any of the expected values.'
        }
        -1978335137 {
            return 'Install location must be provided.'
        }
        -1978335136 {
            return 'Archive malware scan failed.'
        }
        -1978335135 {
            return 'Found at least one version of the package installed.'
        }
        -1978335134 {
            return 'A pin already exists for the package.'
        }
        -1978335133 {
            return 'There is no pin for the package.'
        }
        -1978335132 {
            return 'Unable to open the pin database.'
        }
        -1978335131 {
            return 'One or more applications failed to install'
        }
        -1978335130 {
            return 'One or more applications failed to uninstall'
        }
        -1978335129 {
            return 'One or more queries did not return exactly one match'
        }
        -1978335128 {
            return 'The package has a pin that prevents upgrade.'
        }
        -1978335127 {
            return 'The package currently installed is the stub package'
        }
        -1978335126 {
            return 'Application shutdown signal received'
        }
        -1978335125 {
            return 'Failed to download package dependencies.'
        }
        -1978335124 {
            return 'Failed to download package. Download for offline installation is prohibited.'
        }
        -1978335123 {
            return 'A required service is busy or unavailable. Try again later.'
        }
        -1978335122 {
            return 'The guid provided does not correspond to a valid resume state.'
        }
        -1978335121 {
            return 'The current client version did not match the client version of the saved state.'
        }
        -1978335120 {
            return 'The resume state data is invalid.'
        }
        -1978335119 {
            return 'Unable to open the checkpoint database.'
        }
        -1978335118 {
            return 'Exceeded max resume limit.'
        }
        -1978335117 {
            return 'Invalid authentication info.'
        }
        -1978335116 {
            return 'Authentication method not supported.'
        }
        -1978335115 {
            return 'Authentication failed.'
        }
        -1978335114 {
            return 'Authentication failed. Interactive authentication required.'
        }
        -1978335113 {
            return 'Authentication failed. User cancelled.'
        }
        -1978335112 {
            return 'Authentication failed. Authenticated account is not the desired account.'
        }
        -1978335111 {
            return 'Repair command not found.'
        }
        -1978335110 {
            return 'Repair operation is not applicable.'
        }
        -1978335109 {
            return 'Repair operation failed.'
        }
        -1978335108 {
            return 'The installer technology in use doesn''t support repair.'
        }
        -1978335107 {
            return 'Repair operations involving administrator privileges are not permitted on packages installed within the user scope.'
        }
        -1978334975 {
            return 'Application is currently running. Exit the application then try again.'
        }
        -1978334974 {
            return 'Another installation is already in progress. Try again later.'
        }
        -1978334973 {
            return 'One or more file is being used. Exit the application then try again.'
        }
        -1978334972 {
            return 'This package has a dependency missing from your system.'
        }
        -1978334971 {
            return 'There''s no more space on your PC. Make space, then try again.'
        }
        -1978334970 {
            return 'There''s not enough memory available to install. Close other applications then try again.'
        }
        -1978334969 {
            return 'This application requires internet connectivity. Connect to a network then try again.'
        }
        -1978334968 {
            return 'This application encountered an error during installation. Contact support.'
        }
        -1978334967 {
            return 'Restart your PC to finish installation.'
        }
        -1978334966 {
            return 'Installation failed. Restart your PC then try again.'
        }
        -1978334965 {
            return 'Your PC will restart to finish installation.'
        }
        -1978334964 {
            return 'You cancelled the installation.'
        }
        -1978334963 {
            return 'Another version of this application is already installed.'
        }
        -1978334962 {
            return 'A higher version of this application is already installed.'
        }
        -1978334961 {
            return 'Organization policies are preventing installation. Contact your admin.'
        }
        -1978334960 {
            return 'Failed to install package dependencies.'
        }
        -1978334959 {
            return 'Application is currently in use by another application.'
        }
        -1978334958 {
            return 'Invalid parameter.'
        }
        -1978334957 {
            return 'Package not supported by the system.'
        }
        -1978334956 {
            return 'The installer does not support upgrading an existing package.'
        }
        -1978334719 {
            return 'The Apps and Features Entry for the package could not be found.'
        }
        -1978334718 {
            return 'The install location is not applicable.'
        }
        -1978334717 {
            return 'The install location could not be found.'
        }
        -1978334716 {
            return 'The hash of the existing file did not match.'
        }
        -1978334715 {
            return 'File not found.'
        }
        -1978334714 {
            return 'The file was found but the hash was not checked.'
        }
        -1978334713 {
            return 'The file could not be accessed.'
        }
        -1978286079 {
            return 'The configuration file is invalid.'
        }
        -1978286078 {
            return 'The YAML syntax is invalid.'
        }
        -1978286077 {
            return 'A configuration field has an invalid type.'
        }
        -1978286076 {
            return 'The configuration has an unknown version.'
        }
        -1978286075 {
            return 'An error occurred while applying the configuration.'
        }
        -1978286074 {
            return 'The configuration contains a duplicate identifier.'
        }
        -1978286073 {
            return 'The configuration is missing a dependency.'
        }
        -1978286072 {
            return 'The configuration has an unsatisfied dependency.'
        }
        -1978286071 {
            return 'An assertion for the configuration unit failed.'
        }
        -1978286070 {
            return 'The configuration was manually skipped.'
        }
        -1978286069 {
            return 'A warning was thrown and the user declined to continue execution.'
        }
        -1978286068 {
            return 'The dependency graph contains a cycle which cannot be resolved.'
        }
        -1978286067 {
            return 'The configuration has an invalid field value.'
        }
        -1978286066 {
            return 'The configuration is missing a field.'
        }
        -1978285823 {
            return 'The configuration unit was not installed.'
        }
        -1978285822 {
            return 'The configuration unit could not be found.'
        }
        -1978285821 {
            return 'Multiple matches were found for the configuration unit specify the module to select the correct one.'
        }
        -1978285820 {
            return 'The configuration unit failed while attempting to get the current system state.'
        }
        -1978285819 {
            return 'The configuration unit failed while attempting to test the current system state.'
        }
        -1978285818 {
            return 'The configuration unit failed while attempting to apply the desired state.'
        }
        -1978285817 {
            return 'The module for the configuration unit is available in multiple locations with the same version.'
        }
        -1978285816 {
            return 'Loading the module for the configuration unit failed.'
        }
        -1978285815 {
            return 'The configuration unit returned an unexpected result during execution.'
        }
        -1978285814 {
            return 'A unit contains a setting that requires the config root.'
        }
        -1978285813 {
            return 'Loading the module for the configuration unit failed because it requires administrator privileges to run.'
        }
        default {
            return "Unknown error code: $Result"
        }
    }
}


# Start transcript logging
Start-Transcript -Path $LogPath -Append
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
    Stop-Transcript
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
   Write-Warning "Checking Winget version failed, but Installation will continue."   
}

# Installing / uninststalling the application package
if($Action -eq "install"){
    Write-Output "Install $Name"
    $Arguments = "install --id $id --source $Source --silent --accept-source-agreements --accept-package-agreements --log ""$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$Name-pkg-install.log"""
} else {
    Write-Output "Uninstall $Name"
    $Arguments = "uninstall --id $id --silent --accept-source-agreements --log ""$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\$Name-pkg-uninstall.log"""
}
if($Scope){$Arguments += " --scope $Scope" }

    Write-Output $Arguments
try {
    $process = Start-Process -FilePath "$WingetCliPath" -ArgumentList $Arguments -PassThru -Wait -ErrorAction STOP

    if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 3010 -and $process.ExitCode -ne -1978335189) {
        $ExitMsg = Get-WingetReturnCodeDescription -Decimal $($process.ExitCode)
        Write-Error "$Action action failed with exit code $($process.ExitCode) : $ExitMsg."
        Stop-Transcript
        Exit 3
    } else {
        $ExitMsg = Get-WingetReturnCodeDescription -Decimal $($process.ExitCode)
        Write-Output "$Action action completed with exit code $($process.ExitCode) : $ExitMsg."
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