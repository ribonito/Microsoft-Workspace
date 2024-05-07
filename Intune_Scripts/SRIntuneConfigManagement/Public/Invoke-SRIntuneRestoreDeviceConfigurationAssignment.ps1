function Invoke-SRIntuneRestoreDeviceConfigurationAssignment {
    <#
    .SYNOPSIS
    Restore Intune Device Configuration Assignments
    
    .DESCRIPTION
    Restore Intune Device Configuration Assignments from JSON files per Device Configuration Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SourceFilters
    Assignment filter names and IDs captured from the source tenant

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-SRIntuneRestoreDeviceConfigurationAssignment -Path "C:\temp"
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

    if (-not $SameTenant) {
        If (-not $SourceGroups) {
            $SourceGroups = Import-SRGroupsFromCSV -Path "$Path"
        }
        If (-not $SourceFilters) {
            $SourceFilters = Import-SRFiltersFromCSV -Path "$Path"
        }
    }

    # Get all policies with assignments
    $deviceConfigurations = Get-ChildItem -Path "$Path\Device Configurations\Assignments\*" -Include *.json
    foreach ($deviceConfiguration in $deviceConfigurations) {
        $deviceConfigurationAssignments = Get-Content -LiteralPath $deviceConfiguration.FullName | ConvertFrom-Json
        $deviceConfigurationName = ($deviceConfiguration.BaseName)

        # Get the Device configuration we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceManagement/deviceConfigurations?`$filter=displayName eq '$deviceConfigurationName'&`$select=id,displayName"
            $deviceConfigurationObject = Invoke-MgGraphRequest -Uri $Uri
            if (-not ($deviceConfigurationObject.Value)) {
                Write-Warning "Error retrieving Device configuration for $deviceConfigurationName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving Device configuration for $deviceConfigurationName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($deviceConfigurationAssignment in $deviceConfigurationAssignments) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($deviceConfigurationAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$deviceConfigurationAssignment.target.groupId = $TargetGroupId}
                }
               # Replace assignment filter IDs in the body with the filter id in the target tenant
                $filterIdJson = $($deviceConfigurationAssignment.target.deviceAndAppManagementAssignmentFilterId)
                If($filterIdJson -ne $null){
                    $filterNameCsv = $null
                    $TargetFilterId = $null
                    $filterNameCsv = ($SourceFilters.GetEnumerator() | Where-Object {$_.Key -eq $filterIdJson}).Value
                    if($filterNameCsv){$TargetFilterId = Get-SRAssignedFilterId -FilterName $filterNameCsv}
                    if($TargetFilterId){$deviceConfigurationAssignment.target.deviceAndAppManagementAssignmentFilterId = $TargetFilterId}
                }
            }
            $requestBody.assignments += @{
                "target" = $deviceConfigurationAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceManagement/deviceConfigurations/$($deviceConfigurationObject.Value.id)/assign"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Configuration Assignments"
                "Name"   = $deviceConfigurationObject.Value.displayName
                "Path"   = "Device Configurations\Assignments\$($deviceConfiguration.Name)"
            }
        }
        catch {
            Write-Verbose "$($deviceConfigurationObject.Value.displayName) - Failed to restore Device Configuration Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreDeviceConfigurationAssignment -Path "C:\temp\intunerestore"