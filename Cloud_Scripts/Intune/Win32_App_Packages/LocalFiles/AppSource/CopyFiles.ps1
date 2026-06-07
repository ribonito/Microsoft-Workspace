function Replace-LastSubstring {
    param(
        [string]$str,
        [string]$substr,
        [string]$newstr
    )

    return $str.Remove(($lastIndex = $str.LastIndexOf($substr)),$substr.Length).Insert($lastIndex,$newstr)
}
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
Start-Transcript "$($env:ProgramData)\Microsoft\IntuneManagementExtension\Logs\CopyFiles-$($Version).log"

# Get the current folder where the script is located
$sourceFolderPath = $PSScriptRoot
# Specify the destination folder path
$destinationFolderPath = "C:"

# Create the destination folder if it doesn't exist
if (-not (Test-Path -Path $destinationFolderPath)) {
    New-Item -ItemType Directory -Path $destinationFolderPath
    Log "Destination folder created: $destinationFolderPath"
} else {
    Log "Destination folder already exists: $destinationFolderPath"
}

# Get all files in the source folder
$itemsToCopy = Get-ChildItem -Path $sourceFolderPath -Recurse

# Copy each file from the source folder to the destination folder
foreach ($item in $itemsToCopy) {
    if($item.Name -ne "CopyFiles.ps1"){
        try {
            if(Test-Path -Path $item.FullName -PathType Container){
                $destinationPath = $($item.FullName).replace("$sourceFolderPath","$destinationFolderPath")
                $destinationPath = Replace-LastSubstring $destinationPath $item.Name ""
                Copy-Item -Path $item.FullName -Destination $destinationPath -Force
                Log "Copying $($item.FullName) to $destinationPath"
            } else {
                $destinationPath = $($item.FullName).replace("$sourceFolderPath","$destinationFolderPath")
                Copy-Item -Path $item.FullName -Destination $destinationPath -Force
                Log "Copying $($item.FullName) to $destinationPath"
            }
        } catch {
            Write-Error $_.Exception.Message
            Stop-Transcript
            Exit 3
        }
    }
}

#Set a tag in the registry to avoid further name checks in future
REG add "HKLM\Software\Sunrise\Manage" /v "LocalFiles" /t REG_DWORD /d 1 /f

# Stop transcript logging
Stop-Transcript