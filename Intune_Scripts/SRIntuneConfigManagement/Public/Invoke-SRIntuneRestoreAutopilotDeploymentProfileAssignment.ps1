function Invoke-SRIntuneRestoreAutopilotDeploymentProfileAssignment {
    <#
    .SYNOPSIS
    Restore Intune Autopilot profile Assignments
    
    .DESCRIPTION
    Restore Intune Autopilot profiles Assignments from JSON files per Device Configuration Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SourceFilters
    Assignment filter names and IDs captured from the source tenant

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-Invoke-SRIntuneRestoreAutopilotDeploymentProfileAssignment -Path "C:\temp"
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

    # Check if restore folder exists
    if (-not (Test-Path "$Path\Autopilot Deployment Profiles\Assignments")) {
        Write-Warning "Folder '$Path\Autopilot Deployment Profiles\Assignments' doesn't exist. Skipping restore of Autopilot profile Assignments"
        Return
    }

    if (-not $SameTenant) {
        If (-not $SourceGroups) {
            $SourceGroups = Import-SRGroupsFromCSV -Path "$Path"
        }
    }

    # Get all Autopilotprofiles with assignments
    $Profiles = Get-ChildItem -Path "$Path\Autopilot Deployment Profiles\Assignments\*" -Include *.json
    foreach ($Profile in $Profiles) {
        $ProfileAssignments = Get-Content -LiteralPath $Profile.FullName | ConvertFrom-Json
        $ProfileName = ($Profile.BaseName)

        # Get the Autopilotprofiles we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles?`$filter=displayName eq '$ProfileName'&`$select=id,displayName"
            $ProfileObject = Invoke-MgGraphRequest -Uri $Uri
            if (-not ($ProfileObject.Value)) {
                Write-Warning "Error retrieving Autopilotprofile for $ProfileName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving Autopilot profile for $appProtectionPolicyName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Add assignments to restore to the request body
        foreach ($ProfileAssignment in $ProfileAssignments) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($ProfileAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$ProfileAssignment.target.groupId = $TargetGroupId}
                }
            }
            # Create the base requestBody
            $requestBody = @{
                "target" = $ProfileAssignment.target | Select-Object -Property * -ExcludeProperty deviceAndAppManagementAssignmentFilterType,deviceAndAppManagementAssignmentFilterId
            }

            # Convert the PowerShell object to JSON
            $requestBody = $requestBody | ConvertTo-Json -Depth 100
            #$requestbody
            # Restore the assignments
            try {
                $Uri = "$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles/$($ProfileObject.Value.id)/assignments"
                $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            }
            catch {
                Write-Verbose "$($ProfileObject.Value.displayName) - Failed to restore Autopilotprofiles Assignment(s)" -Verbose
                Write-Error $_ -ErrorAction Continue
            }
        }
        [PSCustomObject]@{
            "Action" = "Restore"
            "Type"   = "Device Configuration Assignments"
            "Name"   = $ProfileObject.Value.displayName
            "Path"   = "Autopilot Deployment Profiles\Assignments\$($Profile.Name)"
        }
    }
}

#Invoke-SRIntuneRestoreAutopilotDeploymentProfileAssignment -Path "C:\temp\intunerestore"