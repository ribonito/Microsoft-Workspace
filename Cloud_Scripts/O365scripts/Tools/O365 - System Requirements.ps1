<#
.SYNOPSIS
    Evaluates system requirements, WMF version, and PowerShell edition for M365 administration.

.DESCRIPTION
    Inspects PowerShell runtime version, operating system details, and PowerShell edition (Core vs Desktop).
    Alerts administrators when the Windows Management Framework (WMF) is below version 5.1 or when
    running on PowerShell Core where legacy modules (e.g. MSOnline) may not be compatible.

.NOTES
    Compatible with Windows PowerShell 5.1 and PowerShell 7+.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\O365 - System Requirements.ps1
    Executes version checks and displays compatibility advice.

.LINK
    https://learn.microsoft.com/powershell/scripting/wmf/overview
    https://learn.microsoft.com/powershell/scripting/install/installing-powershell
#>

[CmdletBinding()]
param ()

# 1. Evaluate PowerShell version
$ps = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Host "PowerShell Version: " -NoNewline -ForegroundColor Yellow

if ($PSVersionTable.PSVersion.Major -lt 5 -or ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -lt 1)) {
    Write-Host $ps -ForegroundColor Red
    Write-Host "`nWarning: " -NoNewline -ForegroundColor Red
    Write-Host "Windows Management Framework needs to be upgraded on this system (PS Version < 5.1)." -ForegroundColor White
    Write-Host "Download WMF 5.1: https://aka.ms/wmf51download" -ForegroundColor Cyan
} else {
    Write-Host $ps -ForegroundColor Green
}

# 2. Evaluate Operating System
if ($IsWindows -or $env:OS -like "*Windows*") {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue |
        Select-Object Caption, Version, OSArchitecture, CSName
    if ($os) {
        Write-Host "Operating System:   $($os.Caption) ($($os.Version) - $($os.OSArchitecture))" -ForegroundColor Cyan
    }
}

# 3. Evaluate PowerShell Edition
Write-Host "PowerShell Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Yellow
if ($PSVersionTable.PSEdition -eq "Core") {
    Write-Host "Notice: Running on PowerShell Core. Legacy modules such as MSOnline and AzureAD require Windows PowerShell 5.1 or the -UseWindowsPowerShell compatibility flag." -ForegroundColor Magenta
}
