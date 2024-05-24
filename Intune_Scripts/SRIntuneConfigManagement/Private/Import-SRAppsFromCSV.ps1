function Import-SRAppsFromCSV {
    <#
    .SYNOPSIS
    Load apps from CSV
     
    .DESCRIPTION
    Load apps from CSV into a hash table
     
    .PARAMETER Path
    Path to backup files
     
    .EXAMPLE
    Import-SRAppsFromCSV -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $Apps = @{}

    # Check if csv file exists
    $CSVFile = "$Path\Client Apps\AppIDs.csv"
    if (-not (Test-Path "$CSVFile")) {
        Write-Output "App reference file $CSVFile wasn't found. We cannot continue."
        Return "Error"
    } else {

    $CsvContent = Import-Csv -Path $CSVFile
    foreach($Row in $CsvContent)
    {
        $Apps[$row.Key]=$Row.Value
    }

    Return $Apps
    }
}

#Import-SRAppsFromCSV -Path "C:\temp\Intunerestore"