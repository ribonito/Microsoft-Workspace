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
    if (-not (Test-Path "$Path\Admin Roles\Assignments")) {
        Write-Warning "Folder '$Path\Admin Roles\Assignments' doesn't exist. Skipping restore of Admin role Assignments"
        Return
    }

    if (-not $SameTenant) {
        If (-not $SourceGroups) {
            $SourceGroups = Import-SRGroupsFromCSV -Path "$Path"
        }
    }

    # Get all Admin roles with assignments
    $adminRoles = Get-ChildItem -Path "$Path\Admin Roles\Assignments\*" -Include *.json
    foreach ($adminRole in $adminRoles) {
        $adminRoleAssignments = Get-Content -LiteralPath $adminRole.FullName | ConvertFrom-Json
        $adminRoleId = ($($adminRole.BaseName -split("__"))[0])

        # Add assignments to restore to the request body
        foreach ($adminRoleAssignment in $adminRoleAssignments) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                #$groupIdJson = $($adminRoleAssignment.members)
                $i=0
                foreach ($groupIdJson in $($adminRoleAssignment.members)){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$adminRoleAssignment.members[$i] = $TargetGroupId}
                    $i+=1
                }
                $i=0
                foreach ($groupIdJson in $($adminRoleAssignment.resourceScopes)){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$adminRoleAssignment.resourceScopes[$i] = $TargetGroupId}
                    $i+=1
                }
            }
            
            # Create the base requestBody
            $requestBody = @{
                "@odata.type" = $adminRoleAssignment.'@odata.type'
                "description" = $adminRoleAssignment.description
                "displayName" = $adminRoleAssignment.displayName
                "members" = $adminRoleAssignment.members
                "resourceScopes" = $adminRoleAssignment.resourceScopes
                "roleDefinition@odata.bind" = "https://graph.microsoft.com/beta/deviceManagement/roleDefinitions('$adminRoleId')"
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceManagement/roleAssignments"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Admin role Assignments"
                "Name"   = $adminRoleObject.Value.displayName
                "Path"   = "Admin Roles\Assignments\$($adminRole.Name)"
            }
        }
        catch {
            Write-Verbose "$($adminRoleAssignment.displayName) - Failed to restore Admin Roles Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
        Start-Sleep -Seconds 5
    }
}

#Invoke-SRIntuneRestoreAdminRoleAssignment -Path "C:\temp\intunerestore"