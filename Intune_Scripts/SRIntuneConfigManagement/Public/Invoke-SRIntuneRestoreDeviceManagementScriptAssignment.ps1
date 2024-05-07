function Invoke-SRIntuneRestoreDeviceManagementScriptAssignment {
    <#
    .SYNOPSIS
    Restore Intune Device Management Script Assignments
    
    .DESCRIPTION
    Restore Intune Device Management Script Assignments from JSON
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SourceFilters
    Assignment filter names and IDs captured from the source tenant

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-SRIntuneRestoreDeviceManagementScriptAssignment -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [hashtable]$SourceGroups,
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
    }

    # Get all policies with assignments
    $deviceConfigurations = Get-ChildItem -Path "$Path\Device Management Scripts\Assignments\*" -Include *.json
    foreach ($deviceConfiguration in $deviceConfigurations) {
        $deviceConfigurationAssignments = Get-Content -LiteralPath $deviceConfiguration.FullName | ConvertFrom-Json
        $deviceConfigurationName = ($deviceConfiguration.BaseName)

        # Get the Device configuration we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceManagement/deviceManagementScripts?`$filter=displayName eq '$deviceConfigurationName'&`$select=id,displayName"
            $deviceConfigurationObject = Invoke-MgGraphRequest -Uri $Uri
            if (-not ($deviceConfigurationObject.Value)) {
                Write-Warning "Error retrieving Device Management Script $deviceConfigurationName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving Device Management Script $deviceConfigurationName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            deviceManagementScriptGroupAssignments = @()
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
            }
            $requestBody.deviceManagementScriptGroupAssignments += @{
                "@odata.type" = "#microsoft.graph.deviceManagementScriptGroupAssignment"
                "targetGroupId" = $deviceConfigurationAssignment.target.groupId
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceManagement/deviceManagementScripts/$($deviceConfigurationObject.Value.id)/assign"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Management Script Assignments"
                "Name"   = $deviceConfigurationObject.Value.displayName
                "Path"   = "Device Management Scripts\Assignments\$($deviceConfiguration.Name)"
            }
        }
        catch {
            Write-Verbose "$($deviceConfigurationObject.Value.displayName) - Failed to restore Device Management Script Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreDeviceManagementScriptAssignment -Path "C:\temp\intunerestore"