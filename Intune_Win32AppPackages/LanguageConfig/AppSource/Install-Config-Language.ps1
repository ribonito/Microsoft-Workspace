param(
    [string]
    $Language = "en-US",
    [Parameter()]
    [ValidateSet('Install','Uninstall')]
    [string]
    $Action = "Install"
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

$Version = "1.0"
Start-Transcript -Path "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\LanguageConfig-$Version-$Language-$Action.log"

$Geoid = 223 #Suisse
$InputLangList = ("en-US","fr-CH","de-CH","it-CH")
try {
    Import-Module -Name LanguagePackManagement
    if ($Action -eq "Install") {
        Install-Language -Language $Language -CopyToSettings

        $LanguageList = New-WinUserLanguageList -Language $Language
        $LanguageList[0].Handwriting = $True
        $LanguageList[0].Spellchecking = $True
        $i=1
        foreach($InputLang in $InputLangList){
            If($InputLang -ne $Language){
                $LanguageList.Add($InputLang)
                $LanguageList[$i].Handwriting = $True
                $LanguageList[$i].Spellchecking = $True 
            }    
        }
        Set-WinUserLanguageList -LanguageList $LanguageList -Force

        Set-WinSystemLocale $Language
        Set-SystemPreferredUILanguage $Language
        Set-WinHomeLocation -GeoID $Geoid
        Set-Culture -CultureInfo $Language
        #The followiong command is only available from Windows11 22H2
        $osBuild = $(gwmi -class win32_operatingsystem).BuildNumber
        Log "OS build is 10.0.$osBuild"
        if($osBuild -ge 22621){
        Copy-UserInternationalSettingsToSystem -WelcomeScreen $True -NewUser $True
        } else {
            Log "Won't run Copy-UserInternationalSettingsToSystem command"
        }
    } else {
        Uninstall-Language -Language $Language
    }
}
catch {
    Log "Failed to install the language pack for $Language `n $($Error[0])"
    Stop-Transcript
    Exit 1
}

REG add "HKLM\Software\Sunrise\Manage" /v "LanguageConfig" /t REG_SZ /d $Language
Stop-Transcript
Exit 3010