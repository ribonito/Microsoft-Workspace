function Invoke-SRIntuneBackupDeviceEnrollmentConfigAssignments {
    <#
    .SYNOPSIS
    Backup Intune Device Enrollment Configuration assignments
     
    .DESCRIPTION
    Backup Intune Device Enrollment Configuration assignments as JSON files per Device Enrollment configuration item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupDeviceEnrollmentConfigAssignments -Path "C:\temp"
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
    $Subfolder = "Device Enrollment\Assignments"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Enrollment configuration assigments
    $Uri = "$ApiVersion/deviceManagement/deviceEnrollmentConfigurations"
    $eConfigs = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($eConfig in $eConfigs) {
        $eConfigType = $($eConfig.deviceEnrollmentConfigurationType)
        $Uri = "$ApiVersion/deviceManagement/deviceEnrollmentConfigurations/$($eConfig.id)/assignments"
        $assignments = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

        if ($assignments) {
            $fileName = ($eConfig.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($eConfigType)_$($fileName).json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Device Enrolment configuration assignment"
                "Name"   = $eConfig.displayName
                "Path"   = "$Subfolder\$($eConfigType)_$($fileName).json"
            }
        }
    }
}

#Invoke-SRIntuneBackupDeviceEnrollmentConfigAssignments -Path "C:\temp\IntuneBackup\FunctionTest"