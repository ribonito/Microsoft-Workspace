function Invoke-SRIntuneRestoreConfigurationPolicyAssignment {
    <#
    .SYNOPSIS
    Restore Intune Settings catalog Configuration Assignments
    
    .DESCRIPTION
    Restore Intune Settings catalog Configuration Assignments from JSON files 
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SourceFilters
    Assignment filter names and IDs captured from the source tenant

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-SRIntuneRestoreConfigurationPolicyAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Settings catalog\Assignments")) {
        Write-Warning "Folder '$Path\Settings catalog\Assignments' doesn't exist. Skipping restore of Settings catalog Configuration Assignments"
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
    $settingsCatalogs = Get-ChildItem -Path "$Path\Settings catalog\Assignments\*" -Include *.json
    foreach ($settingsCatalog in $settingsCatalogs) {
        $settingsCatalogAssignments = Get-Content -LiteralPath $settingsCatalog.FullName | ConvertFrom-Json
        $settingsCatalogName = ($settingsCatalog.BaseName)

        # Get the Settings catalog configuration we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceManagement/configurationPolicies?`$filter=name eq '$settingsCatalogName'&`$select=id,name"
            $settingsCatalogObject = Invoke-MgGraphRequest -Uri $Uri
            if (-not ($settingsCatalogObject.Value)) {
                Write-Warning "Error retrieving Settings catalog configuration for $settingsCatalogName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving Settings catalog configuration for $settingsCatalogName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($settingsCatalogAssignment in $settingsCatalogAssignments) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($settingsCatalogAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$settingsCatalogAssignment.target.groupId = $TargetGroupId}
                }
               # Replace assignment filter IDs in the body with the filter id in the target tenant
                $filterIdJson = $($settingsCatalogAssignment.target.deviceAndAppManagementAssignmentFilterId)
                If($filterIdJson -ne $null){
                    $filterNameCsv = $null
                    $TargetFilterId = $null
                    $filterNameCsv = ($SourceFilters.GetEnumerator() | Where-Object {$_.Key -eq $filterIdJson}).Value
                    if($filterNameCsv){$TargetFilterId = Get-SRAssignedFilterId -FilterName $filterNameCsv}
                    if($TargetFilterId){$settingsCatalogAssignment.target.deviceAndAppManagementAssignmentFilterId = $TargetFilterId}
                }
            }
            $requestBody.assignments += @{
                "target" = $settingsCatalogAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceManagement/configurationPolicies/$($settingsCatalogObject.Value.id)/assign"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Settings catalog Configuration Assignments"
                "Name"   = $settingsCatalogObject.Value.name
                "Path"   = "Settings catalog\Assignments\$($settingsCatalog.Name)"
            }
        }
        catch {
            Write-Verbose "$($settingsCatalogObject.Value.name) - Failed to restore Settings catalog Configuration Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
        Start-Sleep -Seconds 5
    }
}

#Invoke-SRIntuneRestoreConfigurationPolicyAssignment -Path "C:\temp\intunerestore"