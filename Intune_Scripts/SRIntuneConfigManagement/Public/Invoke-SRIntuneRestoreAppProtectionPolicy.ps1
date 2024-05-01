function Invoke-SRIntuneRestoreAppProtectionPolicy {
    <#
    .SYNOPSIS
    Restore Intune App Protection Policy
    
    .DESCRIPTION
    Restore Intune App Protection Policies from JSON files per App Protection Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupAppProtectionPolicy function
    
    .EXAMPLE
    Invoke-SRIntuneRestoreAppProtectionPolicy -Path "C:\temp" -RestoreById $true
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Get all App Protection Policies
    $appProtectionPolicies = Get-ChildItem -Path "$path\App Protection Policies" -File
    
    foreach ($appProtectionPolicy in $appProtectionPolicies) {
        $appProtectionPolicyContent = Get-Content -LiteralPath $appProtectionPolicy.FullName -Raw

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $appProtectionPolicyContent | ConvertFrom-Json
        $appProtectionPolicyDisplayName = $requestBodyObject.displayName
        $DataType = $appProtectionPolicyDisplayName.'@odata.type'
        $DataContext = $appProtectionPolicyDisplayName.'@odata.context'
        # Set SupportsScopeTags to $false, because $true currently returns an HTTP Status 400 Bad Request error.
        if ($requestBodyObject.supportsScopeTags) {
           $requestBodyObject.supportsScopeTags = $false
        }

        $requestBodyObject.PSObject.Properties | Foreach-Object {
            if ($null -ne $_.Value) {
                if ($_.Value.GetType().Name -eq "DateTime") {
                    $_.Value = (Get-Date -Date $_.Value -Format s) + "Z"
                }
            }
            if ($_.Name -eq "apps") {
                $_.Value = $_.Value | select * -ExcludeProperty id,version
            }

        }

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id,createdDateTime,lastModifiedDateTime,version,"@odata.context",apps@odata.context,deployedAppCount | ConvertTo-Json -Depth 100
        #$requestBody
        if ($DataType -eq '#microsoft.graph.androidManagedStoreAppConfiguration' -or $DataType -eq '#microsoft.graph.iosMobileAppConfiguration') {
            $Uri = "$ApiVersion/deviceAppManagement/mobileAppConfigurations"
        } elseif ($DataContext -match "targetedManagedAppConfigurations") {
            $Uri = "$ApiVersion/deviceAppManagement/targetedManagedAppConfigurations"
        } else {
            $Uri = "$ApiVersion/deviceAppManagement/managedAppPolicies"
        }
        # Restore the App Protection Policy
        try {            
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop

            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "App Protection Policy"
                "Name"   = $appProtectionPolicyDisplayName
                "Path"   = "App Protection Policies\$($appProtectionPolicy.Name)"
            }
        }
        catch {
            Write-Verbose "$appProtectionPolicyDisplayName - Failed to restore App Protection Policy" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

Invoke-SRIntuneRestoreAppProtectionPolicy -Path "C:\temp\intunerestore"