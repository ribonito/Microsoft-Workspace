function Invoke-SRIntuneBackupBrandingProfilesAssignments {
    <#
    .SYNOPSIS
    Backup Intune branding Profile assignments
     
    .DESCRIPTION
    Backup Intune branding Profile assignments as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupBrandingProfilesAssignments -Path "C:\temp"
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
    $Subfolder = "Branding profiles\Assignments"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get ids of all profiles
    $Uri = "$ApiVersion/deviceManagement/intuneBrandingProfiles?`select=id,profileName"
    $Profiles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($Profile in $Profiles) {
        $Uri = "$ApiVersion/deviceManagement/intuneBrandingProfiles/$($Profile.id)/assignments"
        $assignments = Invoke-MgGraphRequest -Uri $Uri

        if ($assignments) {
            $fileName = ($Profile.profileName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json -Depth 10 | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Branding Profile assignment"
                "Name"   = $Profile.profileName
                "Path"   = "$Subfolder\$($fileName).json"
            }
        }
    }
}

#Invoke-SRIntuneBackupBrandingProfilesAssignments -Path "C:\temp\IntuneBackup\FunctionTest"