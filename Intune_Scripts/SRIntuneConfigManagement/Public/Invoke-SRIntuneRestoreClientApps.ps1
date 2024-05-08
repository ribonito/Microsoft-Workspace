function Invoke-SRIntuneRestoreClientApps {
    <#
    .SYNOPSIS
    Restore Intune applications
    
    .DESCRIPTION
    Restore Intune applications from JSON files per Device Compliance Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreClientApps -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Client Apps")) {
        Write-Warning "Folder '$Path\Client Apps' doesn't exist. Skipping restore of applications"
        Return
    }

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all applications
    $ClientApps = Get-ChildItem -Path "$Path\Client Apps\*" -File -Include *.json
    foreach ($ClientApp in $ClientApps) {
        $ClientAppContent = Get-Content -LiteralPath $ClientApp.FullName -Raw
        $ClientAppDisplayName = ($ClientAppContent | ConvertFrom-Json).displayName
        $ClientAppType = ($ClientAppContent | ConvertFrom-Json).'@odata.type'

        # Win32 LOB, MSFB and Android managed store app restore is currently not working
        if ($ClientAppType -ne "#microsoft.graph.win32LobApp" -and $ClientAppType -ne "#microsoft.graph.microsoftStoreForBusinessApp" -and $ClientAppType -ne "#microsoft.graph.androidManagedStoreApp" -and $ClientAppType -ne "#microsoft.graph.androidManagedStoreWebApp") {

            # Remove properties that are not available for creating a new application
            $requestBodyObject = $ClientAppContent | ConvertFrom-Json
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

            $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id,createdDateTime,lastModifiedDateTime,'@odata.context',uploadState,publishingState,usedLicenseCount,totalLicenseCount,productKey,licenseType,packageIdentityName,isAssigned,supersededAppCount,dependentAppCount,supersedingAppCount,appAvailability | ConvertTo-Json -Depth 100
            $requestbody
            # Restore the Device Compliance Policy
            try {
                $Uri = "$ApiVersion/deviceAppManagement/mobileApps"
                $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
                [PSCustomObject]@{
                    "Action" = "Restore"
                    "Type"   = "Mobile Application"
                    "Name"   = $ClientAppDisplayName
                    "Path"   = "Client Apps\$($ClientApp.Name)"
                }
            }
            catch {
                Write-Verbose "$($ClientApp.Name) - Failed to restore Application." -Verbose
                Write-Error $_ -ErrorAction Continue
            }
        }
    }
}

#Invoke-SRIntuneRestoreClientApps -Path "C:\temp\Intunerestore"