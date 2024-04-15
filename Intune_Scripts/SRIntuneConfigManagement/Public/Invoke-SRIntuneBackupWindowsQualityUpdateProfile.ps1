function Invoke-SRIntuneBackupWindowsQualityUpdateProfile {
    <#
    .SYNOPSIS
    Backup Intune Windows Quality Update Profiles
     
    .DESCRIPTION
    Backup Intune Windows Quality Update Profiles as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupWindowsQualityUpdateProfile -Path "C:\temp"
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
    $Subfolder = "Windows Quality Update Profiles"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Autopilot profiles
    $Uri = "$ApiVersion/deviceManagement/windowsQualityUpdateProfiles"
    $Profiles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($Profile in $Profiles) {
        $ProfileType = $($Profile.deviceEnrollmentConfigurationType)

        $fileName = ($Profile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $Profile | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Windows Quality Update Profiles"
            "Name"   = $Profile.displayName
            "Path"   = "$Subfolder\$($fileName).json"
        }
    }
}

#Invoke-SRIntuneBackupWindowsQualityUpdateProfile -Path "C:\temp\IntuneBackup\FunctionTest"