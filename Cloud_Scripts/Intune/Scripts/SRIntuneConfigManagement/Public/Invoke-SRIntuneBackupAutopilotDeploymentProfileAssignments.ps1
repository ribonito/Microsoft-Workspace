function Invoke-SRIntuneBackupAutopilotDeploymentProfileAssignments {
    <#
    .SYNOPSIS
    Backup Intune Autopilot Deployment Profile assignments
     
    .DESCRIPTION
    Backup Intune Autopilot Deployment Profile assignments as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupAutopilotDeploymentProfileAssignments -Path "C:\temp"
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
    $Subfolder = "Autopilot Deployment Profiles\Assignments"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Autopilot profile assignments
    $Uri = "$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles"
    $Profiles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($Profile in $Profiles) {
        $Uri = "$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles/$($Profile.id)/assignments"
        $assignments = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

        if ($assignments) {
            $fileName = ($Profile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Autopilot Deployment Profile assignment"
                "Name"   = $Profile.displayName
                "Path"   = "$Subfolder\$($fileName).json"
            }
        }
    }
}

#Invoke-SRIntuneBackupAutopilotDeploymentProfileAssignments -Path "C:\temp\IntuneBackup\FunctionTest"