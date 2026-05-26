function Invoke-SRIntuneRestoreAppConfigurationPolicyAssignment {
    <#
    .SYNOPSIS
    Restore App Configuration Policy Assignments
    
    .DESCRIPTION
    Restore App Configuration Policy Assignments from JSON files per App Configuration Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupAppConfigurationPolicyAssignment function

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SourceFilters
    Assignment filter names and IDs captured from the source tenant

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-SRIntuneRestoreAppConfigurationPolicyAssignment -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [hashtable]$SourceGroups,
        [Parameter(Mandatory = $false)]
        [hashtable]$SourceFilters,
        [Parameter(Mandatory = $false)]
        [boolean]$SameTenant = $false,
        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Check if restore folder exists
    if (-not (Test-Path "$Path\App Configuration Policies\Assignments")) {
        Write-Warning "Folder '$Path\App Configuration Policies\Assignments' doesn't exist. Skipping restore of App Configuration Policy Assignments"
        Return
    }

    if (-not $SameTenant) {
        If (-not $SourceGroups) {
            $SourceGroups = Import-SRGroupsFromCSV -Path "$Path"
        }
        If (-not $SourceFilters) {
            $SourceFilters = Import-SRFiltersFromCSV -Path "$Path"
        }
    }

    # Get all policies with assignments
    $appConfigurationPolicies = Get-ChildItem -Path "$Path\App Configuration Policies\Assignments\*" -Include *.json
    foreach ($appConfigurationPolicy in $appConfigurationPolicies) {
        $appConfigurationPolicyAssignments = Get-Content -LiteralPath $appConfigurationPolicy.FullName | ConvertFrom-Json
        $appConfigurationPolicyId = ($appConfigurationPolicy.BaseName -split " - ")[0]
        $appConfigurationPolicyName = ($appConfigurationPolicy.BaseName -split " - ",2)[-1]

        # Get the App Configuration Policy we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceAppManagement/mobileAppConfigurations?`$filter=displayName eq '$appConfigurationPolicyName'&`$select=id,displayName"
            $appConfigurationPolicyObject = Invoke-MgGraphRequest -Uri $Uri
            if (-not ($appConfigurationPolicyObject.Value)) {
                Write-Warning "Error retrieving App Configuration Policy for $appConfigurationPolicyName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving App Configuration Policy for $appConfigurationPolicyName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($appConfigurationPolicyAssignment in $appConfigurationPolicyAssignments.value) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($appConfigurationPolicyAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$appConfigurationPolicyAssignment.target.groupId = $TargetGroupId}
                }
               # Replace assignment filter IDs in the body with the filter id in the target tenant
                $filterIdJson = $($appConfigurationPolicyAssignment.target.deviceAndAppManagementAssignmentFilterId)
                If($filterIdJson -ne $null){
                    $filterNameCsv = $null
                    $TargetFilterId = $null
                    $filterNameCsv = ($SourceFilters.GetEnumerator() | Where-Object {$_.Key -eq $filterIdJson}).Value
                    if($filterNameCsv){$TargetFilterId = Get-SRAssignedFilterId -FilterName $filterNameCsv}
                    if($TargetFilterId){$appConfigurationPolicyAssignment.target.deviceAndAppManagementAssignmentFilterId = $TargetFilterId}
                }
            }
            $requestBody.assignments += @{
                "target" = $appConfigurationPolicyAssignment.target | Select-Object -Property * #-ExcludeProperty id #deviceAndAppManagementAssignmentFilterId, deviceAndAppManagementAssignmentFilterType
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceAppManagement/mobileAppConfigurations/$($appConfigurationPolicyObject.Value.id)/microsoft.graph.managedDeviceMobileAppConfiguration/assign"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop

            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "App Configuration Policy Assignments"
                "Name"   = $appConfigurationPolicyName
                "Path"   = "App Configuration Policies\Assignments\$($appConfigurationPolicy.Name)"
            }
        }
        catch {
            if ($_.Exception.Message -match "The App Configuration Policy Assignment already exist") {
                Write-Verbose "$($appConfigurationPolicyObject.Value.displayName) - The App Configuration Policy Assignment already exists" -Verbose
            }
            else {
                Write-Verbose "$($appConfigurationPolicyObject.Value.displayName) - Failed to restore App Configuration Policy Assignment(s)" -Verbose
                Write-Error $_ -ErrorAction Continue
            }
        }
        Start-Sleep -Seconds 5
    }
}
#Invoke-SRIntuneRestoreAppConfigurationPolicyAssignment -Path "C:\temp\RestoreTemplate\Mobile"