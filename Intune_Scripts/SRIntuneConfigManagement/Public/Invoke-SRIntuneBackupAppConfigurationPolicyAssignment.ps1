function Invoke-SRIntuneBackupAppConfigurationPolicyAssignment {
    <#
    .SYNOPSIS
    Backup Intune App Configuration Policy Assignments
    
    .DESCRIPTION
    Backup Intune App Configuration Policy Assignments as JSON files per App Configuration Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupAppConfigurationPolicyAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\App Configuration Policies\Assignments")) {
        $null = New-Item -Path "$Path\App Configuration Policies\Assignments" -ItemType Directory
    }

    # Get all assignments from all configurations
    $Uri = "$ApiVersion/deviceAppManagement/mobileAppConfigurations"
    $appConfigurationPolicies = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($appConfigurationPolicy in $appConfigurationPolicies) {
        $Uri = "$ApiVersion/deviceAppManagement/mobileAppConfigurations/$($appConfigurationPolicy.id)/assignments"
        $assignments = Invoke-MgGraphRequest -Uri $Uri

        $fileName = ($appConfigurationPolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $assignments | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\App Configuration Policies\Assignments\$($appConfigurationPolicy.id) - $fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "App Configuration Policy Assignments"
            "Name"   = $appConfigurationPolicy.displayName
            "Path"   = "App Configuration Policies\Assignments\$fileName.json"
        }
    }
}

#Invoke-SRIntuneBackupAppConfigurationPolicyAssignment -Path "C:\temp\IntuneBackup\FunctionTest"