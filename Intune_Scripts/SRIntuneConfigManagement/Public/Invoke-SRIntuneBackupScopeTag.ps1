function Invoke-SRIntuneBackupScopeTag {
    <#
    .SYNOPSIS
    Backup Intune Backup Scope tags
     
    .DESCRIPTION
    Backup Intune Backup Scope tags as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupScopeTag -Path "C:\temp"
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
    # Create folder if not exists
    $Subfolder = "Scope tags"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get Intune cope tags
    $Uri = "$ApiVersion/deviceManagement/roleScopeTags"
    $Profiles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($Profile in $Profiles) {
        if($($Profile.isbuiltin) -ne "true"){
            $fileName = ($Profile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $Profile | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

            #Store group name and id in a hash table
            $ScopeTags.Add($Profile.id, $Profile.displayName)

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Backup Scope Tags"
                "Name"   = $Profile.displayName
                "Path"   = "$Subfolder\$($fileName).json"
            }
        }
    }
    #Store group hash table in a CSV file
    $ScopeTags.GetEnumerator() | Select Key, Value | Export-CSV -path "$Path\$Subfolder\ScopeTags.csv" -NoTypeInformation
}

#Invoke-SRIntuneBackupScopeTag -Path "C:\temp\IntuneBackup\FunctionTest"