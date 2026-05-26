function Invoke-SRIntuneBackupAppConfigurationPolicy {
    <#
    .SYNOPSIS
    Backup Intune App Configuiration Policy
    
    .DESCRIPTION
    Backup Intune App Configuiration Policies as JSON files per App Configuiration Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupAppConfigurationPolicy -Path "C:\temp"
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
    if (-not (Test-Path "$Path\App Configuration Policies")) {
        $null = New-Item -Path "$Path\App Configuration Policies" -ItemType Directory
    }

    # Get all app configuration policies for managed devices
    $Uri = "$ApiVersion/deviceAppManagement/mobileAppConfigurations"
    $appConfigPolicies = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($appConfigPolicy in $appConfigPolicies) {
        $fileName = ($appConfigPolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $appConfigPolicy | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\App Configuration Policies\$fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "App Configuration Policy"
            "Name"   = $appConfigPolicy.displayName
            "Path"   = "App Configuration Policies\$fileName.json"
        }
    }
}

#Invoke-SRIntuneBackupAppConfigurationPolicy -Path "C:\temp\IntuneBackup\functiontest"