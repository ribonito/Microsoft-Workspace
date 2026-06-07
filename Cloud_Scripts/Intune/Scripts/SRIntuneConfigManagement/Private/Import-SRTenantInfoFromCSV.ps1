function Import-SRTenantInfoFromCSV {
    <#
    .SYNOPSIS
    Load filters from CSV
     
    .DESCRIPTION
    Load Tenant information from CSV into a hash table
     
    .PARAMETER Path
    Path to backup files
     
    .EXAMPLE
    Import-SRTenantInfoFromCSV -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $TenantInfo = @{}

    # Check if csv file exists
    $CSVFile = "$Path\Tenant Info\TenantInfo.csv"
    if (-not (Test-Path "$CSVFile")) {
        Write-Output "Tenant info reference file $CSVFile wasn't found. We cannot continue."
        Return "Error"
    } else {

    $CsvContent = Import-Csv -Path $CSVFile
    foreach($Row in $CsvContent)
    {
        $TenantInfo[$row.Key]=$Row.Value
    }

    Return $TenantInfo
    }
}

#Import-SRTenantInfoFromCSV -Path "C:\temp\intunerestore"