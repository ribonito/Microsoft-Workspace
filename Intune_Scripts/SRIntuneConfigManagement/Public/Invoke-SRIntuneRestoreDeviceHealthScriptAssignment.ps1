function Invoke-SRIntuneRestoreDeviceHealthScriptAssignment {
    <#
    .SYNOPSIS
    Restore Intune Device Health Script Assignments
    
    .DESCRIPTION
    Restore Intune Device Health Script Assignments from JSON.
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SourceFilters
    Assignment filter names and IDs captured from the source tenant

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-SRIntuneRestoreDeviceHealthScriptAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Health Scripts\Assignments")) {
        Write-Warning "Folder '$Path\Device Health Scripts\Assignments' doesn't exist. Skipping restore of Device Health Script Assignments"
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
    $deviceHealthScripts = Get-ChildItem -Path "$Path\Device Health Scripts\Assignments\*" -Include *.json
    foreach ($deviceHealthScript in $deviceHealthScripts) {
        $deviceHealthScriptAssignments = Get-Content -LiteralPath $deviceHealthScript.FullName | ConvertFrom-Json
        $deviceHealthScriptName = ($deviceHealthScript.BaseName)

        # Get the Device configuration we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceManagement/deviceHealthScripts?`$filter=displayName eq '$deviceHealthScriptName'&`$select=id,displayName"
            $deviceHealthScriptObject = Invoke-MgGraphRequest -Uri $Uri
            if (-not ($deviceHealthScriptObject.Value)) {
                Write-Warning "Error retrieving Device Health Script assignment for $deviceHealthScriptName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving Device Health Script assignment for $deviceHealthScriptName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            deviceHealthScriptAssignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($deviceHealthScriptAssignment in $deviceHealthScriptAssignments.value) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($deviceHealthScriptAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$deviceHealthScriptAssignment.target.groupId = $TargetGroupId}
                }
               # Replace assignment filter IDs in the body with the filter id in the target tenant
                $filterIdJson = $($deviceHealthScriptAssignment.target.deviceAndAppManagementAssignmentFilterId)
                If($filterIdJson -ne $null){
                    $filterNameCsv = $null
                    $TargetFilterId = $null
                    $filterNameCsv = ($SourceFilters.GetEnumerator() | Where-Object {$_.Key -eq $filterIdJson}).Value
                    if($filterNameCsv){$TargetFilterId = Get-SRAssignedFilterId -FilterName $filterNameCsv}
                    if($TargetFilterId){$deviceHealthScriptAssignment.target.deviceAndAppManagementAssignmentFilterId = $TargetFilterId}
                }
            }
            $requestBody.deviceHealthScriptAssignments += @{
                "target" = $deviceHealthScriptAssignment.target
                "runSchedule" = $deviceHealthScriptAssignment.runSchedule
                "runRemediationScript" = $deviceHealthScriptAssignment.runRemediationScript
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceManagement/deviceHealthScripts/$($deviceHealthScriptObject.Value.id)/assign"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Health Script Assignments"
                "Name"   = $deviceHealthScriptObject.Value.displayName
                "Path"   = "Device Health Scripts\Assignments\$($deviceHealthScript.Name)"
            }
        }
        catch {
            Write-Verbose "$($deviceHealthScriptObject.Value.displayName) - Failed to restore Device Health Script Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreDeviceHealthScriptAssignment -Path "C:\temp\intunerestore"