<#
.SYNOPSIS
    UTL-021 | Generate a Date-Time Timestamp String.

.DESCRIPTION
    PowerShell helper function that outputs a structured date and time string formatted as 'yyyyMMddHHmmss'. 
    Often used to generate unique file names for export logs and reports.

.PRODUCT
    Microsoft 365 / Common Functions

.ORIGINAL_AUTHOR
    O365scripts Contributors (Get-Timestamp classification)
    Reference: https://github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-021 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-021_Get-Timestamp.ps1
    Requires: None.

.EXAMPLE
    $Report | Export-Csv -Encoding utf8 -Path "Report_$(Get-Timestamp).csv"
#>

#region ── Main Program ───────────────────────────────────────────────────────
function Get-Timestamp {
    return Get-Date -Format "yyyyMMddHHmmss"
}
#endregion
