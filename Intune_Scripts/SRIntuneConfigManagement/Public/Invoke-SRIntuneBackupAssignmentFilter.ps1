function Invoke-SRIntuneBackupAssignmentFilter {
    <#
    .SYNOPSIS
    Backup Intune Backup Assignment Filter
     
    .DESCRIPTION
    Backup Intune Backup Assignment Filters as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupAssignmentFilter -Path "C:\temp"
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
    # Create folder if not exists
    $Subfolder = "Assignment Filters"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get Intune Assignment Filters
    $Uri = "$ApiVersion/deviceManagement/assignmentFilters"
    $Profiles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($Profile in $Profiles) {
        $fileName = ($Profile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $Profile | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"
        #Store group name and id in a hash table
        $FilterIDs.Add($Profile.id, $Profile.displayName)

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Backup Assignment Filters"
            "Name"   = $Profile.displayName
            "Path"   = "$Subfolder\$($fileName).json"
        }
    }
    #Store group hash table in a CSV file
    $FilterIDs.GetEnumerator() | Select Key, Value | Export-CSV -path "$Path\$Subfolder\FilterIDs.csv" -NoTypeInformation
}

#Invoke-SRIntuneBackupAssignmentFilter -Path "C:\temp\IntuneBackup\FunctionTest"