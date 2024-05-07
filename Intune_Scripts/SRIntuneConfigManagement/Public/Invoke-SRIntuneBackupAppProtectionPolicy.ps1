function Invoke-SRIntuneBackupAppProtectionPolicy {
    <#
    .SYNOPSIS
    Backup Intune App Protection Policy
    
    .DESCRIPTION
    Backup Intune App Protection Policies as JSON files per App Protection Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupAppProtectionPolicy -Path "C:\temp"
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
    if (-not (Test-Path "$Path\App Protection Policies")) {
        $null = New-Item -Path "$Path\App Protection Policies" -ItemType Directory
    }

    # Get all App Protection Policies
    $Uri = "$ApiVersion/deviceAppManagement/managedAppPolicies"
    $appProtectionPolicies = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($appProtectionPolicy in $appProtectionPolicies) {
        # If Android
        if ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.androidManagedAppProtection') {
            $Uri = "$ApiVersion/deviceAppManagement/androidManagedAppProtections('$($appProtectionPolicy.id)')/?`$expand=apps"
            $appProtectionPolicywApps = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        }
        # Elseif iOS
        elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.iosManagedAppProtection') {
            $Uri = "$ApiVersion/deviceAppManagement/iosManagedAppProtections('$($appProtectionPolicy.id)')/?`$expand=apps"
            $appProtectionPolicywApps = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        }
        # Elseif Windows 10 with enrollment
        elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.mdmWindowsInformationProtectionPolicy') {
            $appProtectionPolicywApps = $appProtectionPolicy
        }
        # Elseif Windows 10 without Enrollment
        elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.windowsInformationProtectionPolicy') {
            $Uri = "$ApiVersion/deviceAppManagement/mdmWindowsInformationProtectionPolicies('$($appProtectionPolicy.id)')/?`$expand=protectedAppLockerFiles,exemptAppLockerFiles"
            $appProtectionPolicywApps = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        }
        # Elseif targeted managed app configuration
        elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.targetedManagedAppConfiguration') {
            $Uri = "$ApiVersion/deviceAppManagement/targetedManagedAppConfigurations('$($appProtectionPolicy.id)')/?`$expand=apps"
            $appProtectionPolicywApps = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        }

        $fileName = ($appProtectionPolicywApps.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $appProtectionPolicywApps.'@odata.type' = $appProtectionPolicy.'@odata.type'
        $appProtectionPolicywApps | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\App Protection Policies\$fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "App Protection Policy"
            "Name"   = $appProtectionPolicywApps.displayName
            "Path"   = "App Protection Policies\$fileName.json"
        }
    }

    # Get all app configuration policies for managed devices
    $Uri = "$ApiVersion/deviceAppManagement/mobileAppConfigurations"
    $appConfigPolicies = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($appConfigPolicy in $appConfigPolicies) {
        $fileName = ($appConfigPolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $appConfigPolicy | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\App Protection Policies\$fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "App Configuration Policy"
            "Name"   = $appConfigPolicy.displayName
            "Path"   = "App Protection Policies\$fileName.json"
        }
    }
}

#Invoke-SRIntuneBackupAppProtectionPolicy -Path "C:\temp\IntuneBackup\functiontest"