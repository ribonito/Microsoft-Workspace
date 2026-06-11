<#
.SYNOPSIS
    UTL-002 | Utility - Clear Cache for Microsoft 365 Applications (Interactive).

.DESCRIPTION
    This script allows users to selectively clear the cache for commonly used
    Microsoft 365 desktop applications. Cache files can cause performance issues,
    login errors, or unexpected behavior.

    For each selected application, the script:
        1. Stops the application process (if running)
        2. Deletes the cache directories (Cache, GPUCache, Temporary Files, IndexedDB, Local Storage)
        3. Optionally restarts the application

    Supported applications:
        1. Microsoft Teams
        2. OneDrive
        3. Outlook
        4. Microsoft Edge
        5. Microsoft Word
        6. Microsoft Excel
        7. Microsoft OneNote

.PRODUCT
    Microsoft 365 Desktop Applications (Windows)

.ORIGINAL_AUTHOR
    Mezba Uddin
    Version: 1.0
    Last Updated: 2024-11-06

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-002 classification & English header)

.VERSION
    1.1

.NOTES
    - No additional PowerShell modules required
    - Save any open work in the target application before running
    - Especially useful when experiencing lag, login issues, or unexpected behavior
    - Run as the affected user (not as Administrator) to access the correct AppData paths

.EXAMPLE
    .\UTL-002_M365-Cache-Cleaning.ps1
    (Interactive menu — select the application to clear)
#>

#region ── Cache Clearing Function ───────────────────────────────────────────
function Clear-Cache {
    param (
        [string]$appName,
        [string]$processName,
        [string]$cachePath,
        [string]$executablePath,
        [string[]]$arguments = @()
    )

    # Stop the application if it's running
    Write-Host "Stopping $appName..."
    Get-Process $processName -ErrorAction SilentlyContinue | Stop-Process -Force

    # Define cache folders to delete (customize for each app as needed)
    $foldersToClear = @(
        "\Cache",
        "\GPUCache",
        "\Temporary Files",
        "\IndexedDB",
        "\Local Storage"
    )

    # Clear cache files
    foreach ($folder in $foldersToClear) {
        $fullPath = "$cachePath$folder"
        if (Test-Path $fullPath) {
            Write-Host "Clearing cache at $fullPath..."
            Remove-Item -Path $fullPath -Recurse -Force
        } else {
            Write-Host "$fullPath not found."
        }
    }

    # Restart the application if an executable path is provided
    if ($executablePath) {
        Write-Host "Restarting $appName..."
        if ($arguments -and $arguments.Count -gt 0) {
            Start-Process -FilePath $executablePath -ArgumentList $arguments
        } else {
            Start-Process -FilePath $executablePath
        }
    }

    Write-Host "$appName cache cleared successfully."
}
#endregion

#region ── Menu Definition & Display ──────────────────────────────────────────
# Define options for Microsoft 365 applications in the desired order
$appOptions = @{
    "1" = @{ Name = "Microsoft Teams"; ProcessName = "Teams"; CachePath = "$env:APPDATA\Microsoft\Teams"; ExecutablePath = "$env:LOCALAPPDATA\Microsoft\Teams\Update.exe"; Arguments = @("--processStart", "Teams.exe") }
    "2" = @{ Name = "OneDrive"; ProcessName = "OneDrive"; CachePath = "$env:LOCALAPPDATA\Microsoft\OneDrive"; ExecutablePath = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"; Arguments = @() }
    "3" = @{ Name = "Outlook"; ProcessName = "OUTLOOK"; CachePath = "$env:LOCALAPPDATA\Microsoft\Outlook"; ExecutablePath = "outlook.exe"; Arguments = @() }
    "4" = @{ Name = "Microsoft Edge"; ProcessName = "msedge"; CachePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default"; ExecutablePath = "msedge.exe"; Arguments = @() }
    "5" = @{ Name = "Microsoft Word"; ProcessName = "WINWORD"; CachePath = "$env:LOCALAPPDATA\Microsoft\Office\Word"; ExecutablePath = "winword.exe"; Arguments = @() }
    "6" = @{ Name = "Microsoft Excel"; ProcessName = "EXCEL"; CachePath = "$env:LOCALAPPDATA\Microsoft\Office\Excel"; ExecutablePath = "excel.exe"; Arguments = @() }
    "7" = @{ Name = "Microsoft OneNote"; ProcessName = "ONENOTE"; CachePath = "$env:LOCALAPPDATA\Microsoft\OneNote"; ExecutablePath = "onenote.exe"; Arguments = @() }
}

# Display options for user selection in correct order
Write-Host "Select a Microsoft 365 application to clear its cache:"
foreach ($key in $appOptions.Keys) {
    Write-Host "$key. $($appOptions[$key].Name)"
}
#endregion

#region ── Execution ──────────────────────────────────────────────────────────
# Get user selection
$selection = Read-Host "Enter the number of your choice"

if ($appOptions.ContainsKey($selection)) {
    $app = $appOptions[$selection]
    Clear-Cache -appName $app.Name -processName $app.ProcessName -cachePath $app.CachePath -executablePath $app.ExecutablePath -arguments $app.Arguments
} else {
    Write-Host "Invalid selection. Please run the script again and select a valid option."
}
#endregion
