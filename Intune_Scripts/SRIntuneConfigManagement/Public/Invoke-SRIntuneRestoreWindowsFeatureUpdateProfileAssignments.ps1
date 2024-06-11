function Invoke-SRIntuneRestoreWindowsFeatureUpdateProfileAssignments {
    <#
    .SYNOPSIS
    Restore Intune Windows Feature Update Profile assignments
    
    .DESCRIPTION
    Restore Intune Windows Feature Update Profile assignments from JSON files
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-SRIntuneRestoreWindowsFeatureUpdateProfileAssignments -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Windows Feature Update Profiles\Assignments")) {
        Write-Warning "Folder '$Path\Windows Feature Update Profiles\Assignmentss' doesn't exist. Skipping restore of Windows Feature Update Profile Assignments"
        Return
    }

    if (-not $SameTenant) {
        If (-not $SourceGroups) {
            $SourceGroups = Import-SRGroupsFromCSV -Path "$Path"
        }
    }

    # Get all policies with assignments
    $FeatureUpdateProfiles = Get-ChildItem -Path "$Path\Windows Feature Update Profiles\Assignments\*" -Include *.json
    foreach ($FeatureUpdateProfile in $FeatureUpdateProfiles) {
        $FeatureUpdateProfileAssignments = Get-Content -LiteralPath $FeatureUpdateProfile.FullName | ConvertFrom-Json
        $FeatureUpdateProfileName = ($FeatureUpdateProfile.BaseName)

        # Get the Device configuration we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceManagement/windowsFeatureUpdateProfiles?`$select=id,displayName"
            $FeatureUpdateProfileObject = $(Invoke-MgGraphRequest -Uri $Uri).Value | where-Object {$_.displayName -Match $FeatureUpdateProfileName}
            if (-not ($FeatureUpdateProfileObject)) {
                Write-Warning "Error retrieving Windows Feature Update Profile assignments for $FeatureUpdateProfileName. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving Windows Feature Update Profile assignments for $FeatureUpdateProfileName, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($FeatureUpdateProfileAssignment in $FeatureUpdateProfileAssignments) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($FeatureUpdateProfileAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$FeatureUpdateProfileAssignment.target.groupId = $TargetGroupId}
                }
            }
            $requestBody.assignments += @{
                "target" = $FeatureUpdateProfileAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceManagement/windowsFeatureUpdateProfiles/$($FeatureUpdateProfileObject.id)/assign"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Windows Feature Update Profile assignments"
                "Name"   = $FeatureUpdateProfileObject.Value.displayName
                "Path"   = "Windows Feature Update Profiles\Assignments\$($FeatureUpdateProfile.Name)"
            }
        }
        catch {
            Write-Verbose "$($FeatureUpdateProfileObject.Value.displayName) - Failed to restore Windows Feature Update Profile assignments" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
        Start-Sleep -Seconds 5
    }
}

#Invoke-SRIntuneRestoreWindowsFeatureUpdateProfileAssignments -Path "C:\temp\intunerestore"