<#
.DESCRIPTION
	This script writes printer mappings defined in MappingsJson variable to a json file on the client system to be read and applied by PrinterMapping script installed in the system as a scheduled task
#>

[CmdletBinding()]
Param()

###########################################################################################
# Start transcript for logging
###########################################################################################

Start-Transcript -Path $(Join-Path "$env:temp" "PrinterMappingJson.log")

###########################################################################################
# Define printer mappings here. To remove mappings, make an empty json.
###########################################################################################
$MappingsJson = @'
{
    "Mappings":
    [
        {
            "Id":0,
            "PrintServer":"\\\\svndes01\\TestPrinter1",
            "Default":"0",
            "PrinterName":"TestPrinter-Cool",
            "GroupFilter":null
        },
        {
            "Id":1,
            "PrintServer":"\\\\svndes01\\TestPrinter2",
            "Default":"1",
            "PrinterName":"TestPrinter-Hot",
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
 	$MappingsJson | Out-File -LiteralPath "$Subfolder\PrinterMappings.json"
} catch {
   	Write-Error $_ -ErrorAction Continue
}

Stop-Transcript
