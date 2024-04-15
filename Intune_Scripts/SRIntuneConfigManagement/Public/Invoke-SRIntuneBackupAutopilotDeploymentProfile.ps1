function Invoke-SRIntuneBackupAutopilotDeploymentProfile {
    <#
    .SYNOPSIS
    Backup Intune Autopilot Deployment Profiles
     
    .DESCRIPTION
    Backup Intune Autopilot Deployment Profiles as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupAutopilotDeploymentProfile -Path "C:\temp"
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
    $Subfolder = "Autopilot Deployment Profiles"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Autopilot profiles
    $Uri = "$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles"
    $Profiles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($Profile in $Profiles) {
        $ProfileType = $($Profile.deviceEnrollmentConfigurationType)

        $fileName = ($Profile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $Profile | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Autopilot Deployment Profile"
            "Name"   = $Profile.displayName
            "Path"   = "$Subfolder\$($fileName).json"
        }
    }
}

#Invoke-SRIntuneBackupAutopilotDeploymentProfile -Path "C:\temp\IntuneBackup\FunctionTest"