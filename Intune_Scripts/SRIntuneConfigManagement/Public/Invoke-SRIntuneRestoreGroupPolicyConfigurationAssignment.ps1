function Invoke-SRIntuneRestoreGroupPolicyConfigurationAssignment {
    <#
    .SYNOPSIS
    Restore Intune Group Policy Configuration Assignments
    
    .DESCRIPTION
    Restore Intune Group Policy Configuration Assignments from JSON files per GroupPolicy Configuration Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SourceFilters
    Assignment filter names and IDs captured from the source tenant

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-SRIntuneRestoreGroupPolicyConfigurationAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Administrative Templates\Assignments")) {
        Write-Warning "Folder '$Path\Administrative Templates\Assignments' doesn't exist. Skipping restore of Administrative Template Configuration Assignments"
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
    $GroupPolicyConfigurations = Get-ChildItem -Path "$Path\Administrative Templates\Assignments\*" -Include *.json
    foreach ($GroupPolicyConfiguration in $GroupPolicyConfigurations) {
        $GroupPolicyConfigurationAssignments = Get-Content -LiteralPath $GroupPolicyConfiguration.FullName | ConvertFrom-Json
        $GroupPolicyConfigurationName = ($GroupPolicyConfiguration.BaseName)

        # Get the GroupPolicy configuration we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceManagement/groupPolicyConfigurations?`$filter=displayName eq '$GroupPolicyConfigurationName'&`$select=id,displayName"
            $GroupPolicyConfigurationObject = Invoke-MgGraphRequest -Uri $Uri
            if (-not ($GroupPolicyConfigurationObject.Value)) {
                Write-Warning "Error retrieving Group Policy configuration for $GroupPolicyConfigurationName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving Group Policy configuration for $GroupPolicyConfigurationName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($GroupPolicyConfigurationAssignment in $GroupPolicyConfigurationAssignments) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($GroupPolicyConfigurationAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$GroupPolicyConfigurationAssignment.target.groupId = $TargetGroupId}
                }
               # Replace assignment filter IDs in the body with the filter id in the target tenant
                $filterIdJson = $($GroupPolicyConfigurationAssignment.target.deviceAndAppManagementAssignmentFilterId)
                If($filterIdJson -ne $null){
                    $filterNameCsv = $null
                    $TargetFilterId = $null
                    $filterNameCsv = ($SourceFilters.GetEnumerator() | Where-Object {$_.Key -eq $filterIdJson}).Value
                    if($filterNameCsv){$TargetFilterId = Get-SRAssignedFilterId -FilterName $filterNameCsv}
                    if($TargetFilterId){$GroupPolicyConfigurationAssignment.target.deviceAndAppManagementAssignmentFilterId = $TargetFilterId}
                }
            }
            $requestBody.assignments += @{
                "target" = $GroupPolicyConfigurationAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceManagement/groupPolicyConfigurations/$($GroupPolicyConfigurationObject.Value.id)/assign"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Group Policy Configuration Assignments"
                "Name"   = $GroupPolicyConfigurationObject.Value.displayName
                "Path"   = "Administrative Templates\Assignments\$($GroupPolicyConfiguration.Name)"
            }
        }
        catch {
            Write-Verbose "$($GroupPolicyConfigurationObject.Value.displayName) - Failed to restore Group Policy Configuration Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreGroupPolicyConfigurationAssignment -Path "C:\temp\intunerestore"