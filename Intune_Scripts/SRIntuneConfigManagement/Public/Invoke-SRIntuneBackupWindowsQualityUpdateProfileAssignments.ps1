function Invoke-SRIntuneBackupWindowsQualityUpdateProfileAssignments {
    <#
    .SYNOPSIS
    Backup Intune Windows Quality Update Profile assignments
     
    .DESCRIPTION
    Backup Intune WindowsQuality Update Profile assignments as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupWindowsQualityUpdateProfileAssignments -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Create folder if not exists
    $Subfolder = "Windows Quality Update Profiles\Assignments"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Windows Quality Update Profiles
    $Uri = "$ApiVersion/deviceManagement/windowsQualityUpdateProfiles"
    $Profiles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($Profile in $Profiles) {
        $Uri = "$ApiVersion/deviceManagement/windowsQualityUpdateProfiles/$($Profile.id)/assignments"
        $assignments = Invoke-MgGraphRequest -Uri $Uri

        if ($assignments) {
            $fileName = ($Profile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments.Value | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Windows Quality Update Profile assignment"
                "Name"   = $Profile.displayName
                "Path"   = "$Subfolder\$($fileName).json"
            }
        }
    }
}

#Invoke-SRIntuneBackupWindowsQualityUpdateProfileAssignments -Path "C:\temp\IntuneBackup\FunctionTest"