function Invoke-SRIntuneBackupWindowsFeatureUpdateProfileAssignments {
    <#
    .SYNOPSIS
    Backup Intune Windows Feature Update Profile assignments
     
    .DESCRIPTION
    Backup Intune WindowsFeature Update Profile assignments as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupWindowsFeatureUpdateProfileAssignments -Path "C:\temp"
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
    $Subfolder = "Windows Feature Update Profiles\Assignments"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Windows Feature Update Profiles
    $Uri = "$ApiVersion/deviceManagement/windowsFeatureUpdateProfiles"
    $Profiles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($Profile in $Profiles) {
        $Uri = "$ApiVersion/deviceManagement/windowsFeatureUpdateProfiles/$($Profile.id)/assignments"
        $assignments = Invoke-MgGraphRequest -Uri $Uri

        if ($assignments) {
            $fileName = ($Profile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments.value | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Windows Feature Update Profile assignment"
                "Name"   = $Profile.displayName
                "Path"   = "$Subfolder\$($fileName).json"
            }
        }
    }
}

#Invoke-SRIntuneBackupWindowsFeatureUpdateProfileAssignments -Path "C:\temp\IntuneBackup\FunctionTest"