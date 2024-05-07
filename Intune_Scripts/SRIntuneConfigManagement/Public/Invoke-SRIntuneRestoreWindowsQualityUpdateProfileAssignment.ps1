function Invoke-SRIntuneRestoreWindowsQualityUpdateProfileAssignments {
    <#
    .SYNOPSIS
    Restore Intune Windows Quality Update Profile assignments
    
    .DESCRIPTION
    Restore Intune Windows Quality Update Profile assignments from JSON files
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-SRIntuneRestoreWindowsQualityUpdateProfileAssignments -Path "C:\temp"
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
    $QualityUpdateProfiles = Get-ChildItem -Path "$Path\Windows Quality Update Profiles\Assignments\*" -Include *.json
    foreach ($QualityUpdateProfile in $QualityUpdateProfiles) {
        $QualityUpdateProfileAssignments = Get-Content -LiteralPath $QualityUpdateProfile.FullName | ConvertFrom-Json
        $QualityUpdateProfileName = ($QualityUpdateProfile.BaseName)

        # Get the Device configuration we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceManagement/windowsQualityUpdateProfiles?`$select=id,displayName"
            $QualityUpdateProfileObject = $(Invoke-MgGraphRequest -Uri $Uri).Value | where-Object {$_.displayName -Match $QualityUpdateProfileName}
            if (-not ($QualityUpdateProfileObject)) {
                Write-Warning "Error retrieving Windows Quality Update Profile assignments for $QualityUpdateProfileName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving Windows Quality Update Profile assignments for $QualityUpdateProfileName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($QualityUpdateProfileAssignment in $QualityUpdateProfileAssignments) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($QualityUpdateProfileAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$QualityUpdateProfileAssignment.target.groupId = $TargetGroupId}
                }
            }
            $requestBody.assignments += @{
                "target" = $QualityUpdateProfileAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceManagement/windowsQualityUpdateProfiles/$($QualityUpdateProfileObject.id)/assign"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Windows Quality Update Profile assignments"
                "Name"   = $QualityUpdateProfileObject.Value.displayName
                "Path"   = "Windows Quality Update Profiles\Assignments\$($QualityUpdateProfile.Name)"
            }
        }
        catch {
            Write-Verbose "$($QualityUpdateProfileObject.Value.displayName) - Failed to restore Windows Quality Update Profile assignments" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreWindowsQualityUpdateProfileAssignments -Path "C:\temp\intunerestore"