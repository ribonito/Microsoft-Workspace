function Invoke-SRIntuneRestoreWindowsDriverUpdateProfileAssignments {
    <#
    .SYNOPSIS
    Restore Intune Windows Driver Update Profile assignments
    
    .DESCRIPTION
    Restore Intune Windows Driver Update Profile assignments from JSON files
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-SRIntuneRestoreWindowsDriverUpdateProfileAssignments -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Windows Driver Update Profiles\Assignments")) {
        Write-Warning "Folder '$Path\Windows Driver Update Profiles\Assignments' doesn't exist. Skipping restore of Windows Driver Update Profile Assignments"
        Return
    }

    if (-not $SameTenant) {
        If (-not $SourceGroups) {
            $SourceGroups = Import-SRGroupsFromCSV -Path "$Path"
        }
    }

    # Get all policies with assignments
    $driverUpdateProfiles = Get-ChildItem -Path "$Path\Windows Driver Update Profiles\Assignments\*" -Include *.json
    foreach ($driverUpdateProfile in $driverUpdateProfiles) {
        $driverUpdateProfileAssignments = Get-Content -LiteralPath $driverUpdateProfile.FullName | ConvertFrom-Json
        $driverUpdateProfileName = ($driverUpdateProfile.BaseName)

        # Get the Device configuration we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceManagement/windowsDriverUpdateProfiles?`$select=id,displayName"
            $driverUpdateProfileObject = $(Invoke-MgGraphRequest -Uri $Uri).Value | where-Object {$_.displayName -Match $driverUpdateProfileName}
            if (-not ($driverUpdateProfileObject)) {
                Write-Warning "Error retrieving Windows Driver Update Profile assignments for $driverUpdateProfileName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving Windows Driver Update Profile assignments for $driverUpdateProfileName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($driverUpdateProfileAssignment in $driverUpdateProfileAssignments) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($driverUpdateProfileAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$driverUpdateProfileAssignment.target.groupId = $TargetGroupId}
                }
            }
            $requestBody.assignments += @{
                "target" = $driverUpdateProfileAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceManagement/windowsDriverUpdateProfiles/$($driverUpdateProfileObject.id)/assign"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Windows Driver Update Profile assignments"
                "Name"   = $driverUpdateProfileObject.Value.displayName
                "Path"   = "Windows Driver Update Profiles\Assignments\$($driverUpdateProfile.Name)"
            }
        }
        catch {
            Write-Verbose "$($driverUpdateProfileObject.Value.displayName) - Failed to restore Windows Driver Update Profile assignments" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
        Start-Sleep -Seconds 5
    }
}

#Invoke-SRIntuneRestoreWindowsDriverUpdateProfileAssignments -Path "C:\temp\intunerestore"