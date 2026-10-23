<#
.SYNOPSIS
    Standard template for Microsoft 365 assessment and reporting automation scripts.

.DESCRIPTION
    Provides a standardized scaffold for administrative report generation scripts. Features
    high-performance data collection using [System.Collections.Generic.List[PSCustomObject]],
    iterative processing, console formatting, optional GUI inspection (Out-GridView), and
    safe UTF-8 CSV report export with timestamped filenames.

.PARAMETER ExportPath
    Optional target path for the generated CSV file. Defaults to user desktop with timestamp.

.EXAMPLE
    .\New.ps1
    Runs the report generation process using default paths and exports results to CSV.

.EXAMPLE
    .\New.ps1 -ExportPath "C:\Reports\M365Audit.csv"
    Executes the report and outputs directly to a specified destination.

.NOTES
    Author: Josep Canas - M365 Solutions Architect
    Template: Script & Report Builder Scaffold
    Version: 2.0

.LINK
    https://learn.microsoft.com/powershell/scripting/developer/cmdlet/cmdlet-overview
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, HelpMessage = "Specify output CSV file path.")]
    [string]$ExportPath = "$env:USERPROFILE\Desktop\Export_$((Get-Date -Format 'yyyyMMdd-HHmmss')).csv"
)

# Step 1: Initialize generic list collection for optimal memory performance
$Report = [System.Collections.Generic.List[PSCustomObject]]::new()

# Step 2: Define or query the source items to audit
$SourceItems = @("SampleItem1", "SampleItem2", "SampleItem3")

# Step 3: Iterate and extract attributes
foreach ($item in $SourceItems) {
    Write-Verbose "Auditing item: $item"

    $ReportLine = [PSCustomObject]@{
        Name        = $item
        Timestamp   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Status      = "Active"
        Description = "Sample audit data for $item"
    }
    $Report.Add($ReportLine)
}

# Step 4: Display summary in console
Write-Host "`n=== Audit Report Preview ===" -ForegroundColor Cyan
$Report | Format-Table -AutoSize

# Step 5: Export structured data to CSV
if (-not [string]::IsNullOrWhiteSpace($ExportPath)) {
    $parentDir = Split-Path -Path $ExportPath -Parent
    if ($parentDir -and -not (Test-Path -Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $Report | Export-Csv -Path $ExportPath -Encoding utf8 -NoTypeInformation
    Write-Host "Report successfully exported to: $ExportPath" -ForegroundColor Green
}
