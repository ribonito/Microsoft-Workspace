function Import-SRSScopeTagsFromCSV {
    <#
    .SYNOPSIS
    Load scope tags from CSV
     
    .DESCRIPTION
    Load scope tags from CSV into a hash table
     
    .PARAMETER Path
    Path to backup files
     
    .EXAMPLE
    Import-SRSScopeTagsFromCSV -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $ScopeTags = @{}

    # Check if csv file exists
    $CSVFile = "$Path\Scope tags\ScopeTags.csv"
    if (-not (Test-Path "$CSVFile")) {
        Write-Warning "Filter reference file $CSVFile wasn't found. We cannot continue."
        Return $null
    } else {

    $CsvContent = Import-Csv -Path $CSVFile
    foreach($Row in $CsvContent)
    {
        $ScopeTags[$row.Key]=$Row.Value
    }

    Return $ScopeTags
    }
}

#Import-SRSScopeTagsFromCSV -Path "C:\temp\Intunerestore"