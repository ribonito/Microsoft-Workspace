<#
.SYNOPSIS
    UTL-034 | O365 System Requirements.

.DESCRIPTION
    Check Windows PowerShell and WMF prerequisites.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-034 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Tools/O365%20-%20System%20Requirements.ps1

.NOTES
    Name: UTL-034_O365-System-Requirements.ps1
    Integrated from O365scripts upstream repository.
#>

<# PowerShell version detection and recommendations. #>
$ps = $PSVersionTable.PSVersion.Major,$PSVersionTable.PSVersion.Minor -join ".";
$os = Get-CimInstance Win32_OperatingSystem | select Caption,Version,ServicePackMajorVersion,OSArchitecture,CSName,WindowsDirectory;
Write-Host -NoNewLine -Fore Yellow "PS Version: ";
if ($ps -lt 5.1) {
	Write-Host -Fore Red $ps;
	Write-Host -NoNewLine -Fore Red "`nWarning: ";
	Write-Host -Fore White "The Windows Management Framework needs to be updated on the system (`$PS < 5.1).";
	Write-Host -NoNewLine -Fore Cyan "Link: "; Write-Host "https://aka.ms/wmf51download";
	Write-Host -NoNewLine -Fore Cyan "Documentation: "; Write-Host "https://docs.microsoft.com/en-us/powershell/scripting/wmf/overview?view=powershell-7";
	} else {Write-Host -Fore Green $ps;}
Write-Host;
if ($PSVersionTable.Edition -eq "Core") {
	Write-Host -NoNewLine -Fore Magenta "`Notice: ";
	Write-Host -Fore White "You are currently running on PS Core which does not support the MSOL module. Other commands or modules may not be available or work as expected.";
	Write-Host;
	}
