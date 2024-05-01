function Invoke-SRIntuneRestoreDeviceCompliancePolicy {
    <#
    .SYNOPSIS
    Restore Intune Device Compliance Policies
    
    .DESCRIPTION
    Restore Intune Device Compliance Policies from JSON files per Device Compliance Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceCompliancePolicy function
    
    .EXAMPLE
    Invoke-SRIntuneRestoreDeviceCompliancePolicy -Path "C:\temp" -RestoreById $true
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [switch]$Assigments,
        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Get all Device Compliance Policies
    $deviceCompliancePolicies = Get-ChildItem -Path "$Path\Device Compliance Policies" -File
    foreach ($deviceCompliancePolicy in $deviceCompliancePolicies) {
        $deviceCompliancePolicyContent = Get-Content -LiteralPath $deviceCompliancePolicy.FullName -Raw
        $deviceCompliancePolicyDisplayName = ($deviceCompliancePolicyContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $deviceCompliancePolicyContent | ConvertFrom-Json
        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, 'scheduledActionsForRule@odata.context' | ConvertTo-Json -Depth 100

        # If missing, adds a default required block scheduled action to the compliance policy request body, as this value is not returned when retrieving compliance policies.
        $requestBodyObject = $requestBody | ConvertFrom-Json
        if (-not ($requestBodyObject.scheduledActionsForRule)) {
            $scheduledActionsForRule = @(
                @{
                    ruleName = "PasswordRequired"
                    scheduledActionConfigurations = @(
                        @{
                            actionType = "block"
                            gracePeriodHours = 0
                            notificationTemplateId = ""
                        }
                    )
                }
            )
            $requestBodyObject | Add-Member -NotePropertyName scheduledActionsForRule -NotePropertyValue $scheduledActionsForRule
            
            # Update the request body reflecting the changes
            $requestBody = $requestBodyObject | ConvertTo-Json -Depth 100
        }

        # Restore the Device Compliance Policy
        try {
            $Uri = "$ApiVersion/deviceManagement/deviceCompliancePolicies"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            #$null = Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody.toString() -Url "deviceManagement/deviceCompliancePolicies" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Compliance Policy"
                "Name"   = $deviceCompliancePolicyDisplayName
                "Path"   = "Device Compliance Policies\$($deviceCompliancePolicy.Name)"
            }
        }
        catch {
            Write-Verbose "$deviceCompliancePolicyDisplayName - Failed to restore Device Compliance Policy" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreDeviceCompliancePolicy -Path "C:\temp\Intunerestore"