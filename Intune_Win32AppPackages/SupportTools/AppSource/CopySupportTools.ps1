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
Start-Transcript "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\SupportTool-$($Version).log"

# Get the current folder where the script is located
$sourceFolderPath = $PSScriptRoot
# Specify the destination folder path
$destinationFolderPath = "$ENV:ProgramFiles\SupportTools"

# Create the destination folder if it doesn't exist
if (-not (Test-Path -Path $destinationFolderPath)) {
    New-Item -ItemType Directory -Path $destinationFolderPath
    Log "Destination folder created: $destinationFolderPath"
} else {
    Log "Destination folder already exists: $destinationFolderPath"
}

# Get all files in the source folder
$itemsToCopy = Get-ChildItem -Path $sourceFolderPath

# Copy each file from the source folder to the destination folder
foreach ($item in $itemsToCopy) {
    if($item.Name -ne "CopySupportTools.ps1"){
        if(Test-Path -Path $item.FullName -PathType Container){
            $destinationPath = Join-Path -Path $destinationFolderPath -ChildPath $item.Name
            Copy-Item -Path $item.FullName -Destination $destinationPath -Force -Recurse
            Log "Copying $($item.FullName) to $destinationPath"
        } else {
            $destinationPath = Join-Path -Path $destinationFolderPath -ChildPath $item.Name
            Copy-Item -Path $item.FullName -Destination $destinationPath -Force
            Log "Copying $($item.FullName) to $destinationPath"
        }
    }
}
Stop-Transcript