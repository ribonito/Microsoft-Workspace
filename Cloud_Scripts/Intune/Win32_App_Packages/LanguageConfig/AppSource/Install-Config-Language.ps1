param(
    [string]
    $Language = "en-US",
    [int]
    $GeoId = 223, #Suisse
    [Parameter()]
    [ValidateSet('Install','Uninstall')]
    [string]
    $Action = "Install",
    [string]
    $TimeZone = "W. Europe Standard Time"
)

function Log() {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$false)] [String] $message
	)

	$ts = get-date -f "yyyy/MM/dd hh:mm:ss tt"
	Write-Output "$ts $message"
}

If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
    }
    Catch {
        Throw "Failed to start $PSCOMMANDPATH"
    }
    Exit
}

$Version = "1.1"
Start-Transcript -Path "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\LanguageConfig-$Version-$Language-$Action.log"

if($Geoid -eq 223){ 
    $InputLangList = ($Language,"en-US","fr-CH","de-CH","it-CH")
} else {
    $InputLangList = ($Language,"en-US")
}
try {
    Import-Module -Name LanguagePackManagement
    if ($Action -eq "Install") {
        Log "Adding display language $Language to the device"
        Install-Language -Language $Language -CopyToSettings

        $LanguageList = New-WinUserLanguageList -Language $Language
        $LanguageList[0].Handwriting = $True
        $LanguageList[0].Spellchecking = $True
        $i=1
        foreach($InputLang in $InputLangList){
            If($InputLang -ne $Language){
                Log "Adding input language $Language"
                $LanguageList.Add($InputLang)
                $LanguageList[$i].Handwriting = $True
                $LanguageList[$i].Spellchecking = $True 
            }    
        }
        Set-WinUserLanguageList -LanguageList $LanguageList -Force

        Log "Setting system locale to $Language"
        Set-WinSystemLocale $Language
        Log "Setting preferred user interface language to $Language"
        Set-SystemPreferredUILanguage $Language
        Log "Setting location to $Geoid"
        Set-WinHomeLocation -GeoID $Geoid
        Log "Setting culture to $Language"
        Set-Culture -CultureInfo $Language
        Log "Setting time zone to $TimeZone"
        Set-TimeZone -Id $TimeZone
        #The followiong command is only available from Windows11 22H2
        $osBuild = $(gwmi -class win32_operatingsystem).BuildNumber
        Log "OS build is 10.0.$osBuild"
        if($osBuild -ge 22621){
            Log "Applying settings to new users"
            Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True
        } else {
            Log "Won't run Copy-UserInternationalSettingsToSystem command as Windows build $osBuild does not support it."
        }
    } else {
        Uninstall-Language -Language $Language
        Log "Removing language $Language from the device"
    }
}
catch {
    Log "Failed to install the language pack for $Language `n $($Error[0])"
    Stop-Transcript
    Exit 1
}

REG add "HKLM\Software\Sunrise\Manage" /v "LanguageConfig" /t REG_SZ /d $Language /f
Stop-Transcript
Exit 3010