<#
.SYNOPSIS
    UTL-006 | Utility - Merge Multiple CSV Files into a Single Autopilot Import CSV.

.DESCRIPTION
    Recursively finds all CSV files in the specified folder, combines them into
    a single merged CSV file, and saves it to a "Merged" subfolder.

    Output file: <Folder>\Merged\ApImport.csv

    Typically used to combine multiple Windows Autopilot hardware hash CSV files
    (exported from different devices or batches) before bulk-importing them into
    the Intune Autopilot service.

.PRODUCT
    Microsoft Intune / Windows Autopilot / Utility

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.PARAMETER Folder
    Path to the folder containing the source CSV files to merge.

.EXAMPLE
    .\UTL-006_Combine-CsvFiles.ps1 -Folder "C:\temp\AutopilotExports"

.NOTES
    - No modules required
    - All CSV files must have the same column structure (standard Autopilot hash format)
    - The Merged subfolder is created automatically if it does not exist
#>


param(
    [Parameter(Mandatory = $true)]
    [string]$Folder
)

if (-not (Test-Path "$Folder\Merged")) {
    $null = New-Item -Path "$Folder\Merged" -ItemType Directory
}

$OutFile = "$Folder\Merged\ApImport.csv"
Get-ChildItem -Path $Folder -Filter *.csv | Select-Object -ExpandProperty FullName | Import-Csv | Export-Csv $OutFile -NoTypeInformation -Append