function Invoke-SRIntuneBackupWindowsDriverUpdateProfileAssignments {
    <#
    .SYNOPSIS
    Backup Intune Windows Driver Update Profile assignments
     
    .DESCRIPTION
    Backup Intune WindowsDriver Update Profile assignments as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupWindowsDriverUpdateProfileAssignments -Path "C:\temp"
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
    $Subfolder = "Windows Driver Update\Assignments"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Windows Driver Update Profiles
    $Uri = "$ApiVersion/deviceManagement/windowsDriverUpdateProfiles"
    $Profiles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($Profile in $Profiles) {
        $Uri = "$ApiVersion/deviceManagement/windowsDriverUpdateProfiles/$($Profile.id)/assignments"
        $assignments = Invoke-MgGraphRequest -Uri $Uri

        if ($assignments) {
            $fileName = ($Profile.id).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Windows Driver Update Profile assignment"
                "Name"   = $Profile.displayName
                "Path"   = "$Subfolder\$($fileName).json"
            }
        }
    }
}

#Invoke-SRIntuneBackupWindowsDriverUpdateProfileAssignments -Path "C:\temp\IntuneBackup\FunctionTest"