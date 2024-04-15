function Invoke-SRIntuneBackupDeviceManagementScriptAssignment {
    <#
    .SYNOPSIS
    Backup Intune Device Management Script Assignments
    
    .DESCRIPTION
    Backup Intune Device Management Script Assignments as JSON files per Device Management Script to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupDeviceManagementScriptAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Management Scripts\Assignments")) {
        $null = New-Item -Path "$Path\Device Management Scripts\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $Uri = "$ApiVersion/deviceManagement/deviceManagementScripts"
    $deviceManagementScripts = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($deviceManagementScript in $deviceManagementScripts) {
        $Uri = "$ApiVersion/deviceManagement/deviceManagementScripts/$($deviceManagementScript.id)/assignments"
        $assignments = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        
        if ($assignments) {
            $fileName = ($deviceManagementScript.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Management Scripts\Assignments\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Device Management Script Assignments"
                "Name"   = $deviceManagementScript.displayName
                "Path"   = "Device Management Scripts\Assignments\$fileName.json"
            }
        }
    }
}

#Invoke-SRIntuneBackupDeviceManagementScriptAssignment -Path "C:\temp\IntuneBackup\FunctionTest"