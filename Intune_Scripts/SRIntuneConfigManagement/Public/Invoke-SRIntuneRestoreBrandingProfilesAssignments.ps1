function Invoke-SRIntuneRestoreBrandingProfilesAssignments {
    <#
    .SYNOPSIS
    Restore Intune Branding profiles Assignments
    
    .DESCRIPTION
    Restore Intune Branding profiles Assignments from JSON files per Device Configuration Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located

    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SourceFilters
    Assignment filter names and IDs captured from the source tenant

    .PARAMETER SameTenant
    True if the source tenant is the same as the target

    .EXAMPLE
    Invoke-Invoke-SRIntuneRestoreBrandingProfilesAssignments -Path "C:\temp"
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

    # Get all Branding profiles with assignments
    $BrandingProfiles = Get-ChildItem -Path "$Path\Branding profiles\Assignments\*" -Include *.json
    foreach ($BrandingProfile in $BrandingProfiles) {
        $BrandingProfileAssignments = Get-Content -LiteralPath $BrandingProfile.FullName | ConvertFrom-Json
        $BrandingProfileName = ($BrandingProfile.BaseName)

        # Get the Branding profiles we are restoring the assignments for
        try {
            $Uri = "$ApiVersion/deviceManagement/intuneBrandingProfiles?`$filter=profileName eq '$BrandingProfileName'&`$select=id,profileName"
            write-host $uri
            $BrandingProfileObject = Invoke-MgGraphRequest -Uri $Uri
            if (-not ($BrandingProfileObject.Value)) {
                Write-Warning "Error retrieving Branding profiles for $BrandingProfileObject. Skipping assignment restore"
                continue
            }
        }
        catch {
            Write-Verbose "Error retrieving Branding profiles for $BrandingProfileObject, does it exist in the Intune tenant? Skipping assignment restore ..." -Verbose
            Write-Error $_ -ErrorAction Continue
            continue
        }

        # Create the base requestBody
        $requestBody = @{
            assignments = @()
        }
        
        # Add assignments to restore to the request body
        foreach ($BrandingProfileAssignment in $BrandingProfileAssignments.value) {
            If (!($SameTenant)) {
                # Replace assignment group IDs in the body with the group id in the target tenant
                $groupIdJson = $($BrandingProfileAssignment.target.groupId)
                If ($groupIdJson -ne $null){
                    $groupNameCsv = $null
                    $TargetGroupId = $null
                    $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                    if($groupNameCsv){$TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv}
                    if($TargetGroupId){$BrandingProfileAssignment.target.groupId = $TargetGroupId}
                }
            $requestBody.assignments += @{
                "target" = $BrandingProfileAssignment.target
            }
        }

        # Convert the PowerShell object to JSON
        $requestBody = $requestBody | ConvertTo-Json -Depth 100
        $requestbody
        # Restore the assignments
        try {
            $Uri = "$ApiVersion/deviceManagement/intuneBrandingProfiles/$($BrandingProfileObject.Value.id)/assign"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Configuration Assignments"
                "Name"   = $BrandingProfileObject.Value.profileName
                "Path"   = "Branding profiles\Assignments\$($BrandingProfile.Name)"
            }
        }
        catch {
            Write-Verbose "$($BrandingProfileObject.Value.profileName) - Failed to restore Branding profiles Assignment(s)" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
    }
}

#Invoke-SRIntuneRestoreBrandingProfilesAssignments -Path "C:\temp\intunerestore"