function Invoke-SRIntuneRestoreAutopilotDeploymentProfile.ps1 {
    <#
    .SYNOPSIS
    Restore Intune Autopilotprofiles Assignments
    
    .DESCRIPTION
    Restore Intune Autopilotprofiles Assignments from JSON files per Device Configuration Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SourceFilters
    Assignment filter names and IDs captured from the source tenant

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-Invoke-SRIntuneRestoreAutopilotDeploymentProfile.ps1 -Path "C:\temp"
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
            Write-Verbose "Error retrieving Autopilotprofiles for $appProtectionPolicyName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
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
                $requestBody.assignments += @{
                    "target" = $ProfileAssignment.target | Select-Object -Property * -ExcludeProperty deviceAndAppManagementAssignmentFilterType,deviceAndAppManagementAssignmentFilterId
                }
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100
        $requestbody
        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles/$($ProfileObject.Value.id)/assignments"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Configuration Assignments"
                "Name"   = $ProfileObject.Value.displayName
                "Path"   = "Autopilot Deployment Profiles\Assignments\$($Profile.Name)"
            }
        }
        catch {
            Write-Verbose "$($ProfileObject.Value.displayName) - Failed to restore Autopilotprofiles Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreAutopilotDeploymentProfile.ps1 -Path "C:\temp\intunerestore"