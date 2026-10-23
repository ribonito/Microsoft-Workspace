<#
.SYNOPSIS
    Manages local Microsoft 365 Apps Click-to-Run activations and build version updates.

.DESCRIPTION
    Inspects installed Office Click-to-Run / Volume licensing activation status using the Office
    Software Protection Platform script (ospp.vbs). Supports removing stale product keys and
    triggering online Click-to-Run client updates or rollbacks to a specific target build version.

.PARAMETER TargetVersion
    Optional specific Office build version to update or downgrade to (e.g., '16.0.17830.20138').

.PARAMETER RemovePartialKey
    Optional 5-character partial product key to remove from the local machine licensing store.

.NOTES
    Must be executed with local Administrator privileges on Windows.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\Office Apps Management.ps1
    Queries and displays local Office activation license status.

.EXAMPLE
    .\Office Apps Management.ps1 -TargetVersion "16.0.17830.20138"
    Triggers Office Click-to-Run update to the specified build number.

.LINK
    https://learn.microsoft.com/deployoffice/overview-licensing-activation-microsoft-365-apps
    https://learn.microsoft.com/officeupdates/update-history-microsoft365-apps-by-date
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TargetVersion,

    [Parameter(Mandatory = $false)]
    [string]$RemovePartialKey
)

# 1. Locate ospp.vbs script across standard installation architectures
$CandidatePaths = @(
    "$env:ProgramFiles\Microsoft Office\Office16\ospp.vbs",
    "${env:ProgramFiles(x86)}\Microsoft Office\Office16\ospp.vbs",
    "$env:ProgramFiles\Microsoft Office\Office15\ospp.vbs",
    "${env:ProgramFiles(x86)}\Microsoft Office\Office15\ospp.vbs"
)

$OsppPath = $null
foreach ($path in $CandidatePaths) {
    if (Test-Path -Path $path) {
        $OsppPath = $path
        break
    }
}

if ($OsppPath) {
    Write-Host "Located OSPP script at: $OsppPath" -ForegroundColor Cyan

    # Remove partial key if requested
    if (-not [string]::IsNullOrWhiteSpace($RemovePartialKey)) {
        Write-Host "Removing partial product key '$RemovePartialKey'..." -ForegroundColor Yellow
        & "$env:windir\System32\cscript.exe" //nologo $OsppPath /unpkey $RemovePartialKey
    }

    # Query current license status
    Write-Host "`n=== Office License Status ===" -ForegroundColor Green
    & "$env:windir\System32\cscript.exe" //nologo $OsppPath /dstatus
}
else {
    Write-Warning "Could not locate ospp.vbs. Verify Microsoft Office is installed on this system."
}

# 2. Trigger Click-to-Run update or rollback if version specified
$c2rClient = "$env:ProgramFiles\Common Files\Microsoft Shared\ClickToRun\OfficeC2RClient.exe"
if (-not [string]::IsNullOrWhiteSpace($TargetVersion) -and (Test-Path -Path $c2rClient)) {
    Write-Host "`nInitiating Office Click-to-Run update to version $TargetVersion..." -ForegroundColor Cyan
    Start-Process -FilePath $c2rClient -ArgumentList "/Update user UpdateVersion=$TargetVersion"
    Write-Host "Office update process launched." -ForegroundColor Green
}
