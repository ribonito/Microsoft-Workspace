function Invoke-SRIntuneRestoreAppConfigurationPolicy {
    <#
    .SYNOPSIS
    Restore Intune App Configuration Policy
    
    .DESCRIPTION
    Restore Intune App Configuration Policies from JSON files per App Configuration Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupAppConfigurationPolicy function
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreAppConfigurationPolicy -Path "C:\temp"
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
    if (-not (Test-Path "$Path\App Configuration Policies")) {
        Write-Warning "Folder '$Path\App Configuration Policies' doesn't exist. Skipping restore of App Configuration Policies"
        Return
    }

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
        $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }
    If (-not $SourceApps) {
        $SourceApps = Import-SRAppsFromCSV -Path "$Path"
    }

    # Get all App Configuration Policies
    $appConfigurationPolicies = Get-ChildItem -Path "$path\App Configuration Policies\*" -Include *.json
    
    foreach ($appConfigurationPolicy in $appConfigurationPolicies) {

        # Get data from the json file
        $appConfigurationPolicyContent = Get-Content -LiteralPath $appConfigurationPolicy.FullName -Raw
        $requestBodyObject = $appConfigurationPolicyContent | ConvertFrom-Json
        $appConfigurationPolicyDisplayName = $requestBodyObject.displayName
        $DataType = $requestBodyObject.'@odata.type'
        $DataContext = $appConfigurationPolicyDisplayName.'@odata.context'

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

        if ($requestBodyObject.targetedMobileApps -and -not($SameTenant)) {

            $i = 0
            foreach ($appIDJson in $requestBodyObject.targetedMobileApps) {
                if($appIDJson -ne "0"){
                    # Replace scope tag IDs in the json with the ids in the target tenant based on scope name
                    $appNameCsv = $null
                    $TargetAppId = $null
                    $appNameCsv = ($SourceApps.GetEnumerator() | Where-Object {$_.Name -eq $appIDJson}).Value
                    if($appNameCsv){$TargetAppId = Get-SRAppId -AppName $appNameCsv}
                    if($TargetAppId){$requestBodyObject.targetedMobileApps[$i] = $TargetAppId}
                }
                $i = $i+1
            }
        }

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject.PSObject.Properties | Foreach-Object {
            if ($null -ne $_.Value) {
                if ($_.Value.GetType().Name -eq "DateTime") {
                    $_.Value = (Get-Date -Date $_.Value -Format s) + "Z"
                }
            }
            if ($_.Name -eq "apps") {
                $_.Value = $_.Value | select * -ExcludeProperty id,version
            }

        }

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id,createdDateTime,lastModifiedDateTime,version,'@odata.context',apps@odata.context,deployedAppCount | ConvertTo-Json -Depth 100
        #$requestBody.toString()
        $Uri = "$ApiVersion/deviceAppManagement/mobileAppConfigurations"

        # Restore the App Configuration Policy
        try {            
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop

            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "App Configuration Policy"
                "Name"   = $appConfigurationPolicyDisplayName
                "Path"   = "App Configuration Policies\$($appConfigurationPolicy.Name)"
            }
        }
        catch {
            Write-Verbose "$appConfigurationPolicyDisplayName - Failed to restore App Configuration Policy" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreAppConfigurationPolicy -Path "C:\temp\Intunerestore"