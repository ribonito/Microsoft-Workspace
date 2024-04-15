function Invoke-SRIntuneBackupDeviceEnrollmentConfig {
    <#
    .SYNOPSIS
    Backup Intune Device Enrollment Configuration
     
    .DESCRIPTION
    Backup Intune Device Enrollment Configuration as JSON files per Device Enrollment configuration item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupDeviceEnrollmentConfig -Path "C:\temp"
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
    $Subfolder = "Device Enrollment"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Enrolment configurations
    $Uri = "$ApiVersion/deviceManagement/deviceEnrollmentConfigurations"
    $eConfigs = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($eConfig in $eConfigs) {
        $eConfigType = $($eConfig.deviceEnrollmentConfigurationType)

        $fileName = ($eConfig.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $eConfig | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($eConfigType)_$($fileName).json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Device Enrolment"
            "Name"   = $eConfig.displayName
            "Path"   = "$Subfolder\$($eConfigType)_$($fileName).json"
        }
    }
}

#Invoke-SRIntuneBackupDeviceEnrollmentConfig -Path "C:\temp\IntuneBackup\FunctionTest"