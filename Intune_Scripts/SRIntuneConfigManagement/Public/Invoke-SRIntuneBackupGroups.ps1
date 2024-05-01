function Invoke-SRIntuneBackupGroups {
    <#
    .SYNOPSIS
    Backup Intune Gropups
     
    .DESCRIPTION
    Backup Intune related AAD groups (filtered) as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .PARAMETER Prefix
    Selects only groups which names start with the Prefix value
     
    .EXAMPLE
    Invoke-SRIntuneBackupGroups -Path "C:\temp" -Prefix "SRMW_"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [string]$Prefix,
        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $GroupIDs = @{}
    #Set filter
    If($Prefix){
        $QueryFilter = "?`$filter=startswith(displayName, '$Prefix')"
    } else {
        $QueryFilter = ""
    }

    # Create folder if not exists
    $Subfolder = "Groups"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all group with names with filter
    $Uri = "$ApiVersion/groups$QueryFilter"
    $Groups = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
    
    foreach ($Group in $Groups) {
        $fileName = ($Group.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $Group | ConvertTo-Json -Depth 10 | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

        #Store group name and id in a hash table
        $GroupIDs.Add($Group.id, $Group.displayName)

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Group"
            "Name"   = $Group.displayName
            "Path"   = "$Subfolder\$($fileName).json"
        }
    }
    #Store group hash table in a CSV file
    $GroupIDs.GetEnumerator() | Select Key, Value | Export-CSV -path "$Path\$Subfolder\GroupIDs.csv" -NoTypeInformation
}

#Invoke-SRIntuneBackupGroups -Path "C:\temp\IntuneBackup\FunctionTest" -Prefix "SRMW"