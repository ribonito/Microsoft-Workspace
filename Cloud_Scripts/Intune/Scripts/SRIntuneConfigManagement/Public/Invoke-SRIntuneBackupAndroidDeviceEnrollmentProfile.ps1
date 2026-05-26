function Invoke-SRIntuneBackupAndroidDeviceEnrollmentProfile {
    <#
    .SYNOPSIS
    Backup Intune Android Device Enrollment Profile
     
    .DESCRIPTION
    Backup Intune Android Device Enrollment Profiles as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupAndroidDeviceEnrollmentProfile -Path "C:\temp"
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
    $Subfolder = "Android Device Enrollment Profiles"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get Intune Assignment Filters
    $Uri = "$ApiVersion/deviceManagement/androidDeviceOwnerEnrollmentProfiles"
    $Profiles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($Profile in $Profiles) {
        $fileName = ($Profile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $Profile | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Backup Android Device Enrollment Profiles"
            "Name"   = $Profile.displayName
            "Path"   = "$Subfolder\$($fileName).json"
        }
    }
}

#Invoke-SRIntuneBackupAndroidDeviceEnrollmentProfile -Path "C:\temp\IntuneBackup\FunctionTest"