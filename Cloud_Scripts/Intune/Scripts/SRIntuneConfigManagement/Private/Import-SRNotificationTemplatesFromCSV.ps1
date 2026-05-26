function Import-SRNotificationTemplatesFromCSV {
    <#
    .SYNOPSIS
    Load Notification templates from CSV
     
    .DESCRIPTION
    Load Notification templates from CSV into a hash table
     
    .PARAMETER Path
    Path to backup files
     
    .EXAMPLE
    Import-SRNotificationTemplatesFromCSV -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $Notifications = @{}

    # Check if csv file exists
    $CSVFile = "$Path\Notification templates\NotifMsgTmpl.csv"
    if (-not (Test-Path "$CSVFile")) {
        Write-Warning "Notification templates reference file $CSVFile wasn't found. We cannot continue."
        Return $null
    } else {

    $CsvContent = Import-Csv -Path $CSVFile
    foreach($Row in $CsvContent)
    {
        $Notifications[$row.Key]=$Row.Value
    }

    Return $Notifications
    }
}

#Import-SRNotificationTemplatesFromCSV -Path "C:\temp\Intunerestore"