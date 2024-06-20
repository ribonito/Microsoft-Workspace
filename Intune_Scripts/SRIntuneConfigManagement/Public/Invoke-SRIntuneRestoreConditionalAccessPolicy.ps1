function Invoke-SRIntuneRestoreConditionalAccessPolicy {
    <#
    .SYNOPSIS
    Restore Intune Conditional Access Policy
    
    .DESCRIPTION
    Restore Intune Conditional Access Policies from JSON files.
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER SourceGroups
    Group names and IDs captured from the source tenant 

    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreConditionalAccessPolicy -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [boolean]$SameTenant = $false,
        [Parameter(Mandatory = $false)]
        [hashtable]$SourceGroups,
        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Check if restore folder exists
    if (-not (Test-Path "$Path\Conditional Access Policies")) {
        Write-Warning "Folder '$Path\Conditional Access Policies' doesn't exist. Skipping restore of Conditional Access Policies"
        Return
    }

    if (-not $SameTenant) {
        If (-not $SourceGroups) {
            $SourceGroups = Import-SRGroupsFromCSV -Path "$Path"
        }
    }

    # Get all Conditional Access Policies
    $caPolicies = Get-ChildItem -Path "$path\Conditional Access Policies\*" -Include *.json
    
    foreach ($caPolicy in $caPolicies) {

        # Get data from the json file
        $caPolicyContent = Get-Content -LiteralPath $caPolicy.FullName -Raw
        $requestBodyObject = $caPolicyContent | ConvertFrom-Json
        $caPolicyDisplayName = $requestBodyObject.displayName

        If (!($SameTenant)) {
            # Replace assignment group IDs in the body with the group id in the  target tenant
            $i=0
            foreach($groupIdJson in $($requestBodyObject.conditions.users.excludeGroups)){
                $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                $TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv
                $requestBodyObject.conditions.users.excludeGroups[$i] = $TargetGroupId
                $i += 1
            }
            $i=0
            foreach($groupIdJson in $($requestBodyObject.conditions.users.includeGroups)){
                $groupNameCsv = ($SourceGroups.GetEnumerator() | Where-Object {$_.Key -eq $groupIdJson}).Value
                $TargetGroupId = Get-SRAssignedGroupId -GroupName $groupNameCsv
                $requestBodyObject.conditions.users.includeGroups[$i] = $TargetGroupId
                $i += 1
            }
        }

        # Check if service proncipals referenced in the policy exist and try to create them if they don't
        foreach ($appId in $($requestBodyObject.conditions.applications.excludeApplications)){
            if($appId -ne "All" -and $appId -ne "Office365"){
                $Uri = "$ApiVersion/servicePrincipals?`$filter=appId eq '$appId'"
                $result = Invoke-MgGraphRequest -Uri $Uri -ErrorAction Stop
                if (-not $($result.value.appid)) {
                    $Uri = "$ApiVersion/servicePrincipals"
                    $requestBody = "{""appId"": ""$appId""}"
                    $result = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop

                    [PSCustomObject]@{
                        "Action" = "Create"
                        "Type"   = "Service principal"
                        "ID"     = $appId
                        "Name"   = "$($result.appDisplayName)"
                    }
                }
            }
        }
        foreach ($appId in $($requestBodyObject.conditions.applications.includeApplications)){
            if($appId -ne "All" -and $appId -ne "Office365"){
                $Uri = "$ApiVersion/servicePrincipals?`$filter=appId eq '$appId'"
                $result = Invoke-MgGraphRequest -Uri $Uri -ErrorAction Stop
                if (-not $($result.value.appid)) {
                    $Uri = "$ApiVersion/servicePrincipals"
                    $requestBody = "{""appId"": ""$appId""}"
                    $result = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop

                    [PSCustomObject]@{
                        "Action" = "Create"
                        "Type"   = "Service principal"
                        "ID"     = $appId
                        "Name"   = "$($result.appDisplayName)"
                    }
                }
            }
        }

        # Remove properties that are not available for creating a new CA policy
        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id,createdDateTime,modifiedDateTime,templateid,grantControls.'authenticationStrength@odata.context' | ConvertTo-Json -Depth 100
        #$requestBody
        $Uri = "$ApiVersion/identity/conditionalAccess/policies"
        # Restore the App Protection Policy
        try {            
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop

            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Conditional Access Policy"
                "Name"   = $caPolicyDisplayName
                "Path"   = "Conditional Access Policies\$($caPolicy.Name)"
            }
        }
        catch {
            Write-Verbose "$caPolicyDisplayName - Failed to restore Conditional Access Policy" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
        Start-Sleep -Seconds 5
    }
}

#Invoke-SRIntuneRestoreConditionalAccessPolicy -Path "C:\temp\Intunerestore"