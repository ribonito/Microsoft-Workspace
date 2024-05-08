function Invoke-SRIntuneRestoreAppProtectionPolicyAssignment {
    <#
    .SYNOPSIS
    Restore App Protection Policy Assignments (excluding managedAndroidStoreApp and managedIOSStoreApp)
    
    .DESCRIPTION
    Restore App Protection Policy Assignments from JSON files per App Protection Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupAppProtectionPolicyAssignment function

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SourceFilters
    Assignment filter names and IDs captured from the source tenant

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-SRIntuneRestoreAppProtectionPolicyAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\App Protection Policies\Assignments")) {
        Write-Warning "Folder '$Path\App Protection Policies\Assignments' doesn't exist. Skipping restore of App Protection Policy Assignments"
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
    $appProtectionPolicies = Get-ChildItem -Path "$Path\App Protection Policies\Assignments\*" -Include *.json
    foreach ($appProtectionPolicy in $appProtectionPolicies) {
        $appProtectionPolicyAssignments = Get-Content -LiteralPath $appProtectionPolicy.FullName | ConvertFrom-Json
        $appProtectionPolicyId = ($appProtectionPolicy.BaseName -split " - ")[0]
        $appProtectionPolicyName = ($appProtectionPolicy.BaseName -split " - ",2)[-1]

        # Get the App Protection Policy we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceAppManagement/managedAppPolicies?`$filter=displayName eq '$appProtectionPolicyName'&`$select=id,displayName"
            $appProtectionPolicyObject = Invoke-MgGraphRequest -Uri $Uri
            if (-not ($appProtectionPolicyObject.Value)) {
                Write-Warning "Error retrieving App Protection Policy for $appProtectionPolicyName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving App Protection Policy for $appProtectionPolicyName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($appProtectionPolicyAssignment in $appProtectionPolicyAssignments) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($appProtectionPolicyAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$appProtectionPolicyAssignment.target.groupId = $TargetGroupId}
                }
               # Replace assignment filter IDs in the body with the filter id in the target tenant
                $filterIdJson = $($appProtectionPolicyAssignment.target.deviceAndAppManagementAssignmentFilterId)
                If($filterIdJson -ne $null){
                    $filterNameCsv = $null
                    $TargetFilterId = $null
                    $filterNameCsv = ($SourceFilters.GetEnumerator() | Where-Object {$_.Key -eq $filterIdJson}).Value
                    if($filterNameCsv){$TargetFilterId = Get-SRAssignedFilterId -FilterName $filterNameCsv}
                    if($TargetFilterId){$appProtectionPolicyAssignment.target.deviceAndAppManagementAssignmentFilterId = $TargetFilterId}
                }
            }
            $requestBody.assignments += @{
                "target"   = $appProtectionPolicyAssignment.target | Select-Object -Property * #-ExcludeProperty deviceAndAppManagementAssignmentFilterId, deviceAndAppManagementAssignmentFilterType
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the assignments
        try {
            # If Android
            if ($($appProtectionPolicyObject.Value.'@odata.type') -eq '#microsoft.graph.androidManagedAppProtection') {
                $Uri = "$ApiVersion/deviceAppManagement/androidManagedAppProtections/$($appProtectionPolicyObject.Value.id)/assign"
                $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            }
            # Elseif iOS
            elseif ($($appProtectionPolicyObject.Value.'@odata.type') -eq '#microsoft.graph.iosManagedAppProtection') {
                $Uri = "$ApiVersion/deviceAppManagement/iosManagedAppProtections/$($appProtectionPolicyObject.Value.id)/assign"
                $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            }
            # Elseif Windows 10 with enrollment
            elseif ($($appProtectionPolicyObject.Value.'@odata.type') -eq '#microsoft.graph.mdmWindowsInformationProtectionPolicy') {
                $Uri = "$ApiVersion/deviceAppManagement/mdmWindowsInformationProtectionPolicies/$($appProtectionPolicyObject.Value.id)/assign"
                $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            }
            # Elseif Windows 10 without Enrollment
            elseif ($($appProtectionPolicyObject.Value.'@odata.type') -eq '#microsoft.graph.windowsInformationProtectionPolicy') {
                $Uri = "$ApiVersion/deviceAppManagement/windowsInformationProtectionPolicies/$($appProtectionPolicyObject.Value.id)/assign"
                $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            }

            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "App Protection Policy Assignments"
                "Name"   = $appProtectionPolicyName
                "Path"   = "App Protection Policies\Assignments\$($appProtectionPolicy.Name)"
            }
        }
        catch {
            if ($_.Exception.Message -match "The App Protection Policy Assignment already exist") {
                Write-Verbose "$($appProtectionPolicyObject.Value.displayName) - The App Protection Policy Assignment already exists" -Verbose
            }
            else {
                Write-Verbose "$($appProtectionPolicyObject.Value.displayName) - Failed to restore App Protection Policy Assignment(s)" -Verbose
                Write-Error $_ -ErrorAction Continue
            }
        }
    }
}
#Invoke-SRIntuneRestoreAppProtectionPolicyAssignment -Path "C:\temp\intunerestore"