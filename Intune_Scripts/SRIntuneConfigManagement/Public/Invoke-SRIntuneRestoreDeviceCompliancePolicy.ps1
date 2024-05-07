function Invoke-SRIntuneRestoreDeviceCompliancePolicy {
    <#
    .SYNOPSIS
    Restore Intune Device Compliance Policies
    
    .DESCRIPTION
    Restore Intune Device Compliance Policies from JSON files per Device Compliance Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceCompliancePolicy function
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreDeviceCompliancePolicy -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [hashtable]$SourceScopeTags,
        [Parameter(Mandatory = $false)]
        [boolean]$SameTenant = $false,
        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all Device Compliance Policies
    $deviceCompliancePolicies = Get-ChildItem -Path "$Path\Device Compliance Policies" -File
    foreach ($deviceCompliancePolicy in $deviceCompliancePolicies) {
        $deviceCompliancePolicyContent = Get-Content -LiteralPath $deviceCompliancePolicy.FullName -Raw
        $deviceCompliancePolicyDisplayName = ($deviceCompliancePolicyContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $deviceCompliancePolicyContent | ConvertFrom-Json
        if ($requestBodyObject.roleScopeTagIds -and -not($SameTenant)) {
            $i = 0
            foreach ($ScopeTagIdJson in $requestBodyObject.roleScopeTagIds) {
                if($ScopeTagIdJson -ne "0"){
                    # Replace scope tag IDs in the json with the ids in the target tenant based on scope name
                    $ScopeTagNameCsv = $null
                    $TargetScopeTagId = $null
                    $ScopeTagNameCsv = ($SourceScopeTags.GetEnumerator() | Where-Object {$_.Name -eq $ScopeTagIdJson}).Value
                    if($ScopeTagNameCsv){$TargetScopeTagId = Get-SRScopeTagId -ScopeTagName $ScopeTagNameCsv}
                    if($TargetScopeTagId){$requestBodyObject.roleScopeTagIds[$i] = $TargetScopeTagId}
                }
                $i = $i+1
            }
        }

        # If missing, adds a default required block scheduled action to the compliance policy request body, as this value is not returned when retrieving compliance policies.
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
        }

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, 'scheduledActionsForRule@odata.context' | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the Device Compliance Policy
        try {
            $Uri = "$ApiVersion/deviceManagement/deviceCompliancePolicies"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
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