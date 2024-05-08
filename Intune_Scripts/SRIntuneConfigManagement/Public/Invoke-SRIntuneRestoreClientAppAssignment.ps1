function Invoke-SRIntuneRestoreClientAppAssignment {
    <#
    .SYNOPSIS
    Restore Intune Client app Assignments
    
    .DESCRIPTION
    Restore Intune Client app Assignments from JSON files.
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SourceFilters
    Assignment filter names and IDs captured from the source tenant

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-SRIntuneRestoreClientAppAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Client Apps\Assignments")) {
        Write-Warning "Folder '$Path\Client Apps\Assignments' doesn't exist. Skipping restore of Client app Assignments"
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

    # Get all apps with assignments
    $apps = Get-ChildItem -Path "$Path\Client Apps\Assignments\*" -Include *.json
    foreach ($app in $apps) {
        $appAssignments = Get-Content -LiteralPath $app.FullName | ConvertFrom-Json
        $appName = ($($app.BaseName -split("__"))[1])

        # Get the object we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceAppManagement/mobileApps?`$filter=displayName eq '$appName'&`$select=id,displayName"
            $appObject = Invoke-MgGraphRequest -Uri $Uri
            if (-not ($appObject.Value)) {
                Write-Warning "Error retrieving Client app for $appName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving Client app for $appName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            mobileAppAssignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($appAssignment in $appAssignments) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($appAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$appAssignment.target.groupId = $TargetGroupId}
                }
               # Replace assignment filter IDs in the body with the filter id in the target tenant
                $filterIdJson = $($appAssignment.target.deviceAndAppManagementAssignmentFilterId)
                If($filterIdJson -ne $null){
                    $filterNameCsv = $null
                    $TargetFilterId = $null
                    $filterNameCsv = ($SourceFilters.GetEnumerator() | Where-Object {$_.Key -eq $filterIdJson}).Value
                    if($filterNameCsv){$TargetFilterId = Get-SRAssignedFilterId -FilterName $filterNameCsv}
                    if($TargetFilterId){$appAssignment.target.deviceAndAppManagementAssignmentFilterId = $TargetFilterId}
                }
            }
            $requestBody.mobileAppAssignments += @{
                "@odata.type" = "#microsoft.graph.mobileAppAssignment"
                "intent" = $appAssignment.intent
                "target" = $appAssignment.target
                "settings" = $appAssignment.settings
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100

        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceAppManagement/mobileApps/$($appObject.Value.id)/assign"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Client app Assignments"
                "Name"   = $appObject.Value.displayName
                "Path"   = "Device Configurations\Assignments\$($app.Name)"
            }
        }
        catch {
            Write-Verbose "$($appObject.Value.displayName) - Failed to restore App Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreClientAppAssignment -Path "C:\temp\intunerestore"