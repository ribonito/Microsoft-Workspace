<#
.DESCRIPTION
	This script writes drive mappings defined in MappingsJson valiable to a json file on the client system to be read and applied by DriveMapping script installed in the system as a scheduled task
#>

[CmdletBinding()]
Param()

###########################################################################################
# Start transcript for logging
###########################################################################################

Start-Transcript -Path $(Join-Path "$env:temp" "DriveMappingJson.log")

###########################################################################################
# Define drive mappings here. To remove mappings, make an empty json.
# If RemoveStaleDrives is enabled all mounted PSdrives from filesystem except os drives get disconnected if not specified in drivemapping config
###########################################################################################
$MappingsJson = @'
{
    "RemoveStaleDrives" : "false",
    "Mappings":
    [
        {
            "Id":1,
            "Path":"\\\\svndes01\\TestShare1",
            "DriveLetter":"S",
            "Label":"TestShare-Cool",
            "GroupFilter":null
        },
        {
            "Id":2,
            "Path":"\\\\svndes01\\TestShare2",
            "DriveLetter":"T",
            "Label":"TestShare-Hot",
            "GroupFilter":null
        }
    ]
}
'@

###########################################################################################
# Write json to %AppData%\Sunrise folder
###########################################################################################
# Create folder if not exists
$Subfolder = "$env:APPDATA\Sunrise"
if (-not (Test-Path "$Subfolder")) {
    $null = New-Item -Path "$Subfolder" -ItemType Directory
}

try {
 	$MappingsJson | Out-File -LiteralPath "$Subfolder\DriveMappings.json"
} catch {
   	Write-Error $_ -ErrorAction Continue
}

Stop-Transcript
