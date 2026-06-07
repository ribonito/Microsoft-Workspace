function Import-SRFiltersFromCSV {
    <#
    .SYNOPSIS
    Load filters from CSV
     
    .DESCRIPTION
    Load filters from CSV into a hash table
     
    .PARAMETER Path
    Path to backup files
     
    .EXAMPLE
    Import-SRFiltersFromCSV -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $FilterIDs = @{}

    # Check if csv file exists
    $CSVFile = "$Path\Assignment Filters\FilterIDs.csv"
    if (-not (Test-Path "$CSVFile")) {
        Write-Output "Filter reference file $CSVFile wasn't found. We cannot continue."
        Return "Error"
    } else {

    $CsvContent = Import-Csv -Path $CSVFile
    foreach($Row in $CsvContent)
    {
        $FilterIDs[$row.Key]=$Row.Value
    }

    Return $FilterIDs
    }
}

#Import-SRFiltersFromCSV -Path "C:\temp\intunerestore"