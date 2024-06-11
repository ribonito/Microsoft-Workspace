function Invoke-SRIntuneRestoreAppProtectionPolicy {
    <#
    .SYNOPSIS
    Restore Intune App Protection Policy
    
    .DESCRIPTION
    Restore Intune App Protection Policies from JSON files per App Protection Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupAppProtectionPolicy function
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreAppProtectionPolicy -Path "C:\temp"
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
    if (-not (Test-Path "$Path\App Protection Policies")) {
        Write-Warning "Folder '$Path\App Protection Policies' doesn't exist. Skipping restore of App Protection Policies"
        Return
    }

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all App Protection Policies
    $appProtectionPolicies = Get-ChildItem -Path "$path\App Protection Policies\*" -Include *.json
    
    foreach ($appProtectionPolicy in $appProtectionPolicies) {

        # Get data from the json file
        $appProtectionPolicyContent = Get-Content -LiteralPath $appProtectionPolicy.FullName -Raw
        $requestBodyObject = $appProtectionPolicyContent | ConvertFrom-Json
        $appProtectionPolicyDisplayName = $requestBodyObject.displayName
        $DataType = $requestBodyObject.'@odata.type'
        $DataContext = $appProtectionPolicyDisplayName.'@odata.context'

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
        #$requestBody
        if ($DataType -eq '#microsoft.graph.androidManagedStoreAppConfiguration' -or $DataType -eq '#microsoft.graph.iosMobileAppConfiguration') {
            $Uri = "$ApiVersion/deviceAppManagement/mobileAppConfigurations"
        } elseif ($DataContext -match "targetedManagedAppConfigurations") {
            $Uri = "$ApiVersion/deviceAppManagement/targetedManagedAppConfigurations"
        } else {
            $Uri = "$ApiVersion/deviceAppManagement/managedAppPolicies"
        }
        # Restore the App Protection Policy
        try {            
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop

            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "App Protection Policy"
                "Name"   = $appProtectionPolicyDisplayName
                "Path"   = "App Protection Policies\$($appProtectionPolicy.Name)"
            }
        }
        catch {
            Write-Verbose "$appProtectionPolicyDisplayName - Failed to restore App Protection Policy" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
        Start-Sleep -Seconds 5
    }
}

#Invoke-SRIntuneRestoreAppProtectionPolicy -Path "C:\temp\Intunerestore"