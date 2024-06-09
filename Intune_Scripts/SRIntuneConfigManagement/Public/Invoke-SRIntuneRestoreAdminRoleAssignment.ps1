function Invoke-SRIntuneRestoreAdminRoleAssignment {
    <#
    .SYNOPSIS
    Restore Intune Admin role Assignments
    
    .DESCRIPTION
    Restore Intune Admin role Assignments from JSON files.
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SourceFilters
    Assignment filter names and IDs captured from the source tenant

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-SRIntuneRestoreAdminRoleAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Configurations\Assignments")) {
        Write-Warning "Folder '$Path\Device Configurations\Assignments' doesn't exist. Skipping restore of Admin role Assignments"
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

    # Get all Admin roles with assignments
    $adminRoles = Get-ChildItem -Path "$Path\Device Configurations\Assignments\*" -Include *.json
    foreach ($adminRole in $adminRoles) {
        $adminRoleAssignments = Get-Content -LiteralPath $adminRole.FullName | ConvertFrom-Json
        $adminRoleName = ($adminRole.BaseName)

        # Get the Admin role we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceManagement/deviceConfigurations?`$filter=displayName eq '$adminRoleName'&`$select=id,displayName"
            $adminRoleObject = Invoke-MgGraphRequest -Uri $Uri
            if (-not ($adminRoleObject.Value)) {
                Write-Warning "Error retrieving Admin role for $adminRoleName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving Admin role for $adminRoleName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($adminRoleAssignment in $adminRoleAssignments) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($adminRoleAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$adminRoleAssignment.target.groupId = $TargetGroupId}
                }
               # Replace assignment filter IDs in the body with the filter id in the target tenant
                $filterIdJson = $($adminRoleAssignment.target.deviceAndAppManagementAssignmentFilterId)
                If($filterIdJson -ne $null){
                    $filterNameCsv = $null
                    $TargetFilterId = $null
                    $filterNameCsv = ($SourceFilters.GetEnumerator() | Where-Object {$_.Key -eq $filterIdJson}).Value
                    if($filterNameCsv){$TargetFilterId = Get-SRAssignedFilterId -FilterName $filterNameCsv}
                    if($TargetFilterId){$adminRoleAssignment.target.deviceAndAppManagementAssignmentFilterId = $TargetFilterId}
                }
            }
            $requestBody.assignments += @{
                "target" = $adminRoleAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceManagement/deviceConfigurations/$($adminRoleObject.Value.id)/assign"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Admin role Assignments"
                "Name"   = $adminRoleObject.Value.displayName
                "Path"   = "Device Configurations\Assignments\$($adminRole.Name)"
            }
        }
        catch {
            Write-Verbose "$($adminRoleObject.Value.displayName) - Failed to restore Device Configuration Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreAdminRoleAssignment -Path "C:\temp\intunerestore"