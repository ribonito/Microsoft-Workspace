function Invoke-SRIntuneRestoreDeviceEnrollmentConfig {
    <#
    .SYNOPSIS
    Restore Intune Device Enrollment Configuration
    
    .DESCRIPTION
    Restore Intune Device Enrollment Configuration from JSON files.
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreDeviceEnrollmentConfig -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Enrollment")) {
        Write-Warning "Folder '$Path\Device Enrollment' doesn't exist. Skipping restore of Device Enrollment configuration profiles"
        Return
    }

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all Device Enrollment Configuration
    $EnrollmentConfigs = Get-ChildItem -Path "$Path\Device Enrollment\*" -Include *.json
    foreach ($EnrollmentConfig in $EnrollmentConfigs) {
        $EnrollmentConfigContent = Get-Content -LiteralPath $EnrollmentConfig.FullName -Raw
        $EnrollmentConfigDisplayName = ($EnrollmentConfigContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $EnrollmentConfigContent | ConvertFrom-Json
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

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the Device Enrollment Configuration
        try {
            $Uri = "$ApiVersion/deviceManagement/deviceEnrollmentConfigurations"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Device Enrollment Configuration"
                "Name"   = $EnrollmentConfigDisplayName
                "Path"   = "Device Enrollment\$($EnrollmentConfig.Name)"
            }
        }
        catch {
            Write-Verbose "$EnrollmentConfigDisplayName - Failed to restore Device Enrollment Configuration" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
        Start-Sleep -Seconds 5
    }
}

#Invoke-SRIntuneRestoreDeviceEnrollmentConfig -Path "C:\temp\Intunerestore"