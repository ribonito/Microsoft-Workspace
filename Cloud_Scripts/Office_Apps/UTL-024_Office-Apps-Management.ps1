<#
.SYNOPSIS
    UTL-024 | Office Apps Activation and Version Update Management.

.DESCRIPTION
    PowerShell utility script to query, add, or remove Office Click-to-Run and legacy Volume Licensing activation keys 
    using the Office Software Protection Platform script (ospp.vbs). Also supports forcing/updating Click-to-Run apps 
    to a specific version build.

.PRODUCT
    Microsoft 365 / Office Apps

.ORIGINAL_AUTHOR
    O365scripts Contributors (Office Apps Management classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/Office%20Apps/Office%20Apps%20Management.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-024 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-024_Office-Apps-Management.ps1
    Requires: Local Administrator privileges and Microsoft Office client installed.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$Version = "16.0.13801.20360"
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Select which folder to run the OSPP vbs script from
$ListPathOspp = @{
    "Office 2016 (x64 or x86)" = "$env:ProgramFiles\Microsoft Office\Office16\ospp.vbs"
    "Office 2016 (x86/64)"     = "${env:ProgramFiles(x86)}\Microsoft Office\Office16\ospp.vbs"
    "Office 2013 (x64 or x86)" = "$env:ProgramFiles\Microsoft Office\Office15\ospp.vbs"
    "Office 2013 (x86/64)"     = "${env:ProgramFiles(x86)}\Microsoft Office\Office15\ospp.vbs"
    "Office 2010 (x64 or x86)" = "$env:ProgramFiles\Microsoft Office\Office14\ospp.vbs"
    "Office 2010 (x86/64)"     = "${env:ProgramFiles(x86)}\Microsoft Office\Office14\ospp.vbs"
    "Office 2007 (x86)"        = "$env:ProgramFiles\Microsoft Office\Office13\ospp.vbs"
    "Office 2007 (x86/64)"     = "${env:ProgramFiles(x86)}\Microsoft Office\Office13\ospp.vbs"
}

$PathOspp = $ListPathOspp | Out-GridView -OutputMode Single

if (!(Get-Item $PathOspp.Value -ErrorAction SilentlyContinue)) {
    Write-Host -NoNewline "Unable to find the OSPP script in: "
    Write-Host -ForegroundColor Yellow $PathOspp.Value
}

# Get the list of current Office activation keys
& "$env:windir\System32\cscript.exe" $PathOspp.Value /dstatus

# Adjust the XXXXX with the activation key you want to remove and run once per key
# & "$env:windir\System32\cscript.exe" $PathOspp.Value /unpkey XXXXX

# Update or downgrade Office Apps to a specific version
Start-Process "$env:ProgramFiles\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe" -ArgumentList "/Update user UpdateVersion=$Version"
#endregion
