function Invoke-SRIntuneRestoreGroupPolicyConfiguration {
    <#
    .SYNOPSIS
    Restore Intune Group Policy Configurations
    
    .DESCRIPTION
    Restore Intune Group Policy Configurations from JSON files per Group Policy Configuration Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupGroupPolicyConfigurations function
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreGroupPolicyConfiguration -Path "C:\temp" -RestoreById $true
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
    if (-not (Test-Path "$Path\Administrative Templates")) {
        Write-Warning "Folder '$Path\Administrative Templates' doesn't exist. Skipping restore of Administrative Template Configurations"
        Return
    }

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all Group Policy Configurations
    $groupPolicyConfigurations = Get-ChildItem -Path "$Path\Administrative Templates\*" -Include *.json

    foreach ($groupPolicyConfiguration in $groupPolicyConfigurations) {
        $groupPolicyConfigurationContent = Get-Content -LiteralPath $groupPolicyConfiguration.FullName -Raw | ConvertFrom-Json
        
        if ($groupPolicyConfigurationContent.Policy.roleScopeTagIds -and -not($SameTenant)) {
            $i = 0
            foreach ($ScopeTagIdJson in $groupPolicyConfigurationContent.Policy.roleScopeTagIds) {
                if($ScopeTagIdJson -ne "0"){
                    # Replace scope tag IDs in the json with the ids in the target tenant based on scope name
                    $ScopeTagNameCsv = $null
                    $TargetScopeTagId = $null
                    $ScopeTagNameCsv = ($SourceScopeTags.GetEnumerator() | Where-Object {$_.Name -eq $ScopeTagIdJson}).Value
                    if($ScopeTagNameCsv){$TargetScopeTagId = Get-SRScopeTagId -ScopeTagName $ScopeTagNameCsv}
                    if($TargetScopeTagId){$groupPolicyConfigurationContent.Policy.roleScopeTagIds[$i] = $TargetScopeTagId}
                }
                $i = $i+1
            }
        }

        # Restore the Group Policy Configuration
        try {
            $groupPolicyConfigurationRequestBody = $groupPolicyConfigurationContent.Policy | Select-Object -Property * -ExcludeProperty lastModifiedDateTime, createdDateTime, id
            $Uri = "$ApiVersion/deviceManagement/groupPolicyConfigurations"
            $groupPolicyConfigurationObject = Invoke-MgGraphRequest -Method POST -Body ($groupPolicyConfigurationRequestBody | ConvertTo-Json).toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop

            foreach ($groupPolicyConfigurationSetting in $groupPolicyConfigurationContent.Definitions) {
                $Uri = "$ApiVersion/deviceManagement/groupPolicyConfigurations/$($groupPolicyConfigurationObject.id)/definitionValues"
                $groupPolicyDefinitionValue = Invoke-MgGraphRequest -Method POST -Body ($groupPolicyConfigurationSetting | ConvertTo-Json -Depth 100).toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
                $Uri = "$ApiVersion/groupPolicyConfigurations/$($groupPolicyConfigurationObject.id)/definitionValues/$($groupPolicyDefinitionValue.id)/definition"
            }
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Administrative Template"
                "Name"   = $groupPolicyConfigurationObject.displayName
                "Path"   = "Administrative Templates\$($groupPolicyConfiguration.Name)"
            }
        }
        catch {
            Write-Verbose "$($groupPolicyConfiguration.BaseName) - Failed to restore Group Policy Configuration and/or (one or more) Settings" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreGroupPolicyConfiguration -Path "C:\temp\Intunerestore"
