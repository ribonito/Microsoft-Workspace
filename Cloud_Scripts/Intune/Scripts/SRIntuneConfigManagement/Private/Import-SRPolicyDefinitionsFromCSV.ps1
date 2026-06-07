function Import-SRPolicyDefinitionsFromCSV {
    <#
    .SYNOPSIS
    Load Policy Definitions from CSV
     
    .DESCRIPTION
    Load Policy Definitions from CSV into a hash table
     
    .PARAMETER Path
    Path to backup files
     
    .EXAMPLE
    Import-SRPolicyDefinitionsFromCSV -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Check if csv file exists
    $CSVFile = "$Path\Administrative Templates\Definitions.csv"
    if (-not (Test-Path "$CSVFile")) {
        Write-Output "App reference file $CSVFile wasn't found. We cannot continue."
        Return "Error"
    } else {

    $CsvContent = Import-Csv -Path $CSVFile
    Return $CsvContent
    }
}

#Import-SRPolicyDefinitionsFromCSV -Path "C:\temp\Intunerestore"