function Invoke-SRIntuneBackupWindowsFeatureUpdateProfile {
    <#
    .SYNOPSIS
    Backup Intune Windows Feature Update Profiles
     
    .DESCRIPTION
    Backup Intune Windows Feature Update Profiles as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupWindowsFeatureUpdateProfile -Path "C:\temp"
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
    $Subfolder = "Windows Feature Update Profiles"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Autopilot profiles
    $Uri = "$ApiVersion/deviceManagement/windowsFeatureUpdateProfiles"
    $Profiles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
    foreach ($Profile in $Profiles) {
        $fileName = ($Profile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $Profile | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Windows Feature Update Profiles"
            "Name"   = $Profile.displayName
            "Path"   = "$Subfolder\$($fileName).json"
        }
    }
}

#Invoke-SRIntuneBackupWindowsFeatureUpdateProfile -Path "C:\temp\IntuneBackup\FunctionTest"