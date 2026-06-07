function Invoke-SRIntuneRestoreDeviceManagementIntentAssignments {
    <#
    .SYNOPSIS
    Restore Intune Device Management Intent Assignments
    
    .DESCRIPTION
    Restore Intune Device Management Intent Assignments from JSON.
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SourceFilters
    Assignment filter names and IDs captured from the source tenant

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-SRIntuneRestoreDeviceManagementIntentAssignments -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Management Intents\Assignments")) {
        Write-Warning "Folder '$Path\Device Management Intents\Assignments' doesn't exist. Skipping restore of Device Management Intent Assignments"
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
    $managementIntents = Get-ChildItem -Path "$Path\Device Management Intents\Assignments\*" -Include *.json
    foreach ($managementIntent in $managementIntents) {
        $managementIntentAssignments = Get-Content -LiteralPath $managementIntent.FullName | ConvertFrom-Json
        $managementIntentName = ($managementIntent.BaseName)
        # Get the Device Management Intent we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceManagement/intents?`$filter=displayName eq '$managementIntentName'&`$select=id,displayName"
            $managementIntentObject = Invoke-MgGraphRequest -Uri $Uri
            if (-not ($managementIntentObject.Value)) {
                Write-Warning "Error retrieving Device Management Intent for $managementIntentName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving Device Management Intent for $managementIntentName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($managementIntentAssignment in $managementIntentAssignments) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($managementIntentAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$managementIntentAssignment.target.groupId = $TargetGroupId}
                }
               # Replace assignment filter IDs in the body with the filter id in the target tenant
                $filterIdJson = $($managementIntentAssignment.target.deviceAndAppManagementAssignmentFilterId)
                If($filterIdJson -ne $null){
                    $filterNameCsv = $null
                    $TargetFilterId = $null
                    $filterNameCsv = ($SourceFilters.GetEnumerator() | Where-Object {$_.Key -eq $filterIdJson}).Value
                    if($filterNameCsv){$TargetFilterId = Get-SRAssignedFilterId -FilterName $filterNameCsv}
                    if($TargetFilterId){$managementIntentAssignment.target.deviceAndAppManagementAssignmentFilterId = $TargetFilterId}
                }
            }
            $requestBody.assignments += @{
                "target" = $managementIntentAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceManagement/intents/$($managementIntentObject.Value.id)/assign"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Management Intent Assignments"
                "Name"   = $managementIntentObject.Value.displayName
                "Path"   = "Device Management Intents\Assignments\$($managementIntent.Name)"
            }
        }
        catch {
            Write-Verbose "$($managementIntentObject.Value.displayName) - Failed to restore Device Management Intent Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
        Start-Sleep -Seconds 5
    }
}

#Invoke-SRIntuneRestoreDeviceManagementIntentAssignments -Path "C:\temp\intunerestore"