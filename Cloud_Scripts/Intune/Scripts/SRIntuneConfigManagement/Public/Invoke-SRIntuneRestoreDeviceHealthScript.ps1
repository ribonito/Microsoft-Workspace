function Invoke-SRIntuneRestoreDeviceHealthScript {
    <#
    .SYNOPSIS
    Restore Intune Device Health Scripts
    
    .DESCRIPTION
    Restore Intune Device Health Scripts from JSON files.
    
    .PARAMETER Path
    Root path where backup files are located,
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreDeviceHealthScript -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Health Scripts")) {
        Write-Warning "Folder '$Path\Device Health Scripts' doesn't exist. Skipping restore of Device Health Scripts"
        Return
    }

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all device management scripts
    $deviceHealthScripts = Get-ChildItem -Path "$Path\Device Health Scripts" -File
    foreach ($deviceHealthScript in $deviceHealthScripts) {
        $deviceHealthScriptContent = Get-Content -LiteralPath $deviceHealthScript.FullName -Raw
        $deviceHealthScriptDisplayName = ($deviceHealthScriptContent | ConvertFrom-Json).displayName  
        
        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $deviceHealthScriptContent | ConvertFrom-Json
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
        #$requestBody
        # Restore the device management script
        try {
            $Uri = "$ApiVersion/deviceManagement/deviceHealthScripts"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Health Script"
                "Name"   = $deviceHealthScriptDisplayName
                "Path"   = "Device Health Scripts\$($deviceHealthScript.Name)"
            }
        }
        catch {
            Write-Verbose "$deviceHealthScriptDisplayName - Failed to restore Device Health Script" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
        Start-Sleep -Seconds 5
    }
}

#Invoke-SRIntuneRestoreDeviceHealthScript -Path "C:\temp\Intunerestore"
