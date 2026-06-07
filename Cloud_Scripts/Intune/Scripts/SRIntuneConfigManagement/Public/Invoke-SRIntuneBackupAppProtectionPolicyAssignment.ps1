function Invoke-SRIntuneBackupAppProtectionPolicyAssignment {
    <#
    .SYNOPSIS
    Backup Intune App Protection Policy Assignments
    
    .DESCRIPTION
    Backup Intune App Protection Policy Assignments as JSON files per App Protection Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupAppProtectionPolicyAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\App Protection Policies\Assignments")) {
        $null = New-Item -Path "$Path\App Protection Policies\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $Uri = "$ApiVersion/deviceAppManagement/managedAppPolicies"
    $appProtectionPolicies = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($appProtectionPolicy in $appProtectionPolicies) {
        # If Android
        if ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.androidManagedAppProtection') {
            $Uri = "$ApiVersion/deviceAppManagement/androidManagedAppProtections('$($appProtectionPolicy.id)')/assignments"
            $assignments = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        }
        # Elseif iOS
        elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.iosManagedAppProtection') {
            $Uri = "$ApiVersion/deviceAppManagement/iosManagedAppProtections('$($appProtectionPolicy.id)')/assignments"
            $assignments = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        }
        # Elseif Windows 10 with enrollment
        elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.mdmWindowsInformationProtectionPolicy') {
            $Uri = "$ApiVersion/deviceAppManagement/mdmWindowsInformationProtectionPolicies('$($appProtectionPolicy.id)')/assignments"
            $assignments = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        }
        # Elseif Windows 10 without enrollment
        elseif ($appProtectionPolicy.'@odata.type' -eq '#microsoft.graph.windowsInformationProtectionPolicy') {
            $Uri = "$ApiVersion/deviceAppManagement/windowsInformationProtectionPolicies('$($appProtectionPolicy.id)')/assignments"
            $assignments = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        }
        else {
            # Not supported App Protection Policy
            continue
        }

        $fileName = ($appProtectionPolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $assignments | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\App Protection Policies\Assignments\$($appProtectionPolicy.id) - $fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "App Protection Policy Assignments"
            "Name"   = $appProtectionPolicy.displayName
            "Path"   = "App Protection Policies\Assignments\$fileName.json"
        }
    }
}

#Invoke-SRIntuneBackupAppProtectionPolicyAssignment -Path "C:\temp\IntuneBackup\FunctionTest"