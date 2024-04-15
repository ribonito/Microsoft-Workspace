function Invoke-SRIntuneBackupGroupPolicyConfigurationAssignment {
    <#
    .SYNOPSIS
    Backup Intune Group Policy Configuration Assignments
    
    .DESCRIPTION
    Backup Intune Group Policy Configuration Assignments as JSON files per Group Policy Configuration Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupGroupPolicyConfigurationAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Administrative Templates\Assignments")) {
        $null = New-Item -Path "$Path\Administrative Templates\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $Uri = "$ApiVersion/deviceManagement/groupPolicyConfigurations"
    $groupPolicyConfigurations = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($groupPolicyConfiguration in $groupPolicyConfigurations) {
        $Uri = "$ApiVersion/deviceManagement/groupPolicyConfigurations/$($groupPolicyConfiguration.id)/assignments"
        $assignments = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        
        if ($assignments) {
            $fileName = ($groupPolicyConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Administrative Templates\Assignments\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Administrative Template Assignments"
                "Name"   = $groupPolicyConfiguration.displayName
                "Path"   = "Administrative Templates\Assignments\$fileName.json"
            }
        }
    }
}

#Invoke-SRIntuneBackupGroupPolicyConfigurationAssignment -Path "C:\temp\IntuneBackup\FunctionTest"