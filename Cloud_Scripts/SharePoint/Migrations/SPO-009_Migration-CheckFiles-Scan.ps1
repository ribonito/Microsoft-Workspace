<#
.SYNOPSIS
    SPO-009 | Scan and Log Local Files for SharePoint Online Migration.

.DESCRIPTION
    PowerShell script that recursively scans a specified local or network directory for all files, 
    collects their file paths, last write timestamps, and sizes, and exports them into a semicolon-separated 
    CSV file. This serves as the input inventory for the SPO-010 analyzer script.

.PRODUCT
    SharePoint Online / Migration

.ORIGINAL_AUTHOR
    Toni Pohl, Christoph Wilfing, Martina Grom - atwork.at

.MAINTAINER
    Josep Canas - M365 Solutions Architect (SPO-009 classification)

.VERSION
    1.0

.NOTES
    Name: SPO-009_Migration-CheckFiles-Scan.ps1
    Requires: File system read permissions for the target scan directory.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
# The folder you want to run through.
$folder = "C:\Temp"
# The files in that folder will be written to that file: 
$result = ".\SPO-Migration-CheckFiles-files-demo.csv"
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
Write-Output "SPO-009_Migration-CheckFiles-Scan.ps1`nGet a recursive list of all files with last modified date and file size in a CSV file."

Get-ChildItem $folder -Recurse | `
    Where-Object { !$_.PSIsContainer } | `
    Select-Object FullName, LastWriteTime, Length | `
    Export-Csv -NoTypeInformation -Delimiter ';' -Path $result

Write-Output "Done. Check $($result)"
#endregion
