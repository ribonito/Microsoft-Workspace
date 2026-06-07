function Invoke-SRIntuneBackupDeviceConfigurationAssignment {
    <#
    .SYNOPSIS
    Backup Intune Device Configuration Assignments
    
    .DESCRIPTION
    Backup Intune Device Configuration Assignments as JSON files per Device Configuration Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupDeviceConfigurationAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Configurations\Assignments")) {
        $null = New-Item -Path "$Path\Device Configurations\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $Uri = "$ApiVersion/deviceManagement/deviceConfigurations"
    $deviceConfigurations = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($deviceConfiguration in $deviceConfigurations) {
        $Uri = "$ApiVersion/deviceManagement/deviceConfigurations/$($deviceConfiguration.id)/assignments"
        $assignments = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        if ($assignments) {
            $fileName = ($deviceConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Configurations\Assignments\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Device Configuration Assignments"
                "Name"   = $deviceConfiguration.displayName
                "Path"   = "Device Configurations\Assignments\$fileName.json"
            }
        }
    }
}

#Invoke-SRIntuneBackupDeviceConfigurationAssignment -Path "C:\temp\IntuneBackup\FunctionTest"