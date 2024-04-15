function Import-SRGroupsFromCSV {
    <#
    .SYNOPSIS
    Load AAD groups from CSV
     
    .DESCRIPTION
    Load AAD groups from CSV into a hash table
     
    .PARAMETER Path
    Path to backup files
     
    .EXAMPLE
    Import-SRGroupsFromCSV -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $GroupIDs = @{}

    # Check if csv file exists
    $CSVFile = "$Path\Groups\GroupIDs.csv"
    if (-not (Test-Path "$CSVFile")) {
        Write-Output "Group reference file $CSVFile wasn't found. We cannot continue."
        Return "Error"
    } else {

    $GroupIDs = Import-Csv -Path $CSVFile
    Return $GroupIDs
    }
}
