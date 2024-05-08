function Invoke-SRIntuneRestoreAutopilotDeploymentProfile {
    <#
    .SYNOPSIS
    Restore Intune Autopilot profiles
    
    .DESCRIPTION
    Restore Intune Autopilot profiles from JSON files in the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreAutopilotDeploymentProfile -Path "C:\temp" -Assignments
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [hashtable]$SourceScopeTags,
        [Parameter(Mandatory = $false)]
        [boolean]$SameTenant = $false,
        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Check if restore folder exists
    if (-not (Test-Path "$Path\Autopilot Deployment Profiles")) {
        Write-Warning "Folder '$Path\Autopilot Deployment Profiles' doesn't exist. Skipping restore of Autopilot profiles"
        Return
    }

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all device configurations
    $Profiles = Get-ChildItem -Path "$path\Autopilot Deployment Profiles\*" -Include *.json
    
    foreach ($Profile in $Profiles) {
        $ProfileContent = Get-Content -LiteralPath $Profile.FullName -Raw
        $ProfileDisplayName = ($ProfileContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating action
        $requestBodyObject = $ProfileContent | ConvertFrom-Json
        if ($requestBodyObject.roleScopeTagIds -and -not($SameTenant)) {
            $i = 0
            foreach ($ScopeTagIdJson in $requestBodyObject.roleScopeTagIds) {
                if($ScopeTagIdJson -ne "0"){
                    # Replace scope tag IDs in the json with the ids in the target tenant based on scope name
                    $ScopeTagNameCsv = $null
                    $TargetScopeTagId = $null
                    $ScopeTagNameCsv = ($SourceScopeTags.GetEnumerator() | Where-Object {$_.Name -eq $ScopeTagIdJson}).Value
                    if($ScopeTagNameCsv){$TargetScopeTagId = Get-SRScopeTagId -ScopeTagName $ScopeTagNameCsv}
                    if($TargetScopeTagId){$requestBodyObject.roleScopeTagIds[$i] = $TargetScopeTagId}
                }
                $i = $i+1
            }
        }

        $requestBodyObject.PSObject.Properties | Foreach-Object {
            if ($null -ne $_.Value) {
                if ($_.Value.GetType().Name -eq "DateTime") {
                    $_.Value = (Get-Date -Date $_.Value -Format s) + "Z"
                }
            }
        }

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the device configuration
        try {
            $Uri = "$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Configuration"
                "Name"   = $ProfileDisplayName
                "Path"   = "Autopilot Deployment Profiles\$($Profile.Name)"
            }
        }
        catch {
            Write-Verbose "$ProfileDisplayName - Failed to restore Autopilot policy" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreAutopilotDeploymentProfile -Path "C:\temp\Intunerestore"