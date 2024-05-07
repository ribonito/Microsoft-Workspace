function Invoke-SRIntuneBackupDeviceManagementIntentAssignments {
    <#
    .SYNOPSIS
    Backup Intune Device Management Intents Assignments
    
    .DESCRIPTION
    Backup Intune Device Management Intents Assignmentsas JSON files per Device Management Intent to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupDeviceManagementIntentAssignments -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Management Intents\Assignments")) {
        $null = New-Item -Path "$Path\Device Management Intents\Assignments" -ItemType Directory
    }

    Write-Verbose "Requesting Intents"
    $Uri = "$ApiVersion/deviceManagement/intents"
    $intents = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($intent in $intents) {
        # Get the corresponding assignments
        Write-Verbose "Requesting assignments"
        $Uri = "$ApiVersion/deviceManagement/intents/$($intent.id)/assignments"
        $assignment = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        
        if($($assignment.id)) {
            $fileName = ($intent.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignment | ConvertTo-Json | Out-File -LiteralPath "$path\Device Management Intents\Assignments\$($fileName).json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Device Management Intent Assignments"
                "Name"   = $intent.displayName
                "Path"   = "Device Management Intents\Assignments\$($fileName).json"
            }
        }
    }
}

#Invoke-SRIntuneBackupDeviceManagementIntentAssignments -Path "C:\temp\IntuneBackup\FunctionTest"