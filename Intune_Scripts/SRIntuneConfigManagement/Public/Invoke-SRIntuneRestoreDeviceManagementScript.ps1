function Invoke-SRIntuneRestoreDeviceManagementScript {
    <#
    .SYNOPSIS
    Restore Intune Device Management Scripts
    
    .DESCRIPTION
    Restore Intune Device Management Scripts from JSON files per Device Management Script from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located, created with the Invoke-IntuneBackupDeviceManagementScript function
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreDeviceManagementScript -Path "C:\temp" -RestoreById $true
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
    if (-not (Test-Path "$Path\Device Management Scripts")) {
        Write-Warning "Folder '$Path\Device Management Scripts' doesn't exist. Skipping restore of Device Management Scripts"
        Return
    }

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all device management scripts
    $deviceManagementScripts = Get-ChildItem -Path "$Path\Device Management Scripts" -File
    foreach ($deviceManagementScript in $deviceManagementScripts) {
        $deviceManagementScriptContent = Get-Content -LiteralPath $deviceManagementScript.FullName -Raw
        $deviceManagementScriptDisplayName = ($deviceManagementScriptContent | ConvertFrom-Json).displayName  
        
        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $deviceManagementScriptContent | ConvertFrom-Json
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

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime | ConvertTo-Json
        $requestBody
        # Restore the device management script
        try {
            $Uri = "$ApiVersion/deviceManagement/deviceManagementScripts"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Management Script"
                "Name"   = $deviceManagementScriptDisplayName
                "Path"   = "Device Management Scripts\$($deviceManagementScript.Name)"
            }
        }
        catch {
            Write-Verbose "$deviceManagementScriptDisplayName - Failed to restore Device Management Script" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreDeviceManagementScript -Path "C:\temp\Intunerestore"
