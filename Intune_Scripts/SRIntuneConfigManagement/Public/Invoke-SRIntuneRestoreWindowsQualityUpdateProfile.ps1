function Invoke-SRIntuneRestoreWindowsQualityUpdateProfile {
    <#
    .SYNOPSIS
    Restore Intune Windows Quality Update Profile
    
    .DESCRIPTION
    Restore Intune Windows Quality Update Profile from JSON files
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreWindowsQualityUpdateProfile -Path "C:\temp"
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

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all device configurations
    $QualityUpdateProfiles = Get-ChildItem -Path "$path\Windows Quality Update Profiles\*" -Include *.json
    
    foreach ($QualityUpdateProfile in $QualityUpdateProfiles) {
        $QualityUpdateProfileContent = Get-Content -LiteralPath $QualityUpdateProfile.FullName -Raw
        $QualityUpdateProfileDisplayName = ($QualityUpdateProfileContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $QualityUpdateProfileContent | ConvertFrom-Json
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

        $requestBodyObject.expeditedUpdateSettings.qualityUpdateRelease = (Get-Date -Date $($requestBodyObject.expeditedUpdateSettings.qualityUpdateRelease) -Format s) + "Z"
        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version | ConvertTo-Json -Depth 100
        # Restore the device configuration
        try {
            $Uri = "$ApiVersion/deviceManagement/windowsQualityUpdateProfiles"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Windows Quality Update Profile"
                "Name"   = $QualityUpdateProfileDisplayName
                "Path"   = "Windows Quality Update Profiles\$($QualityUpdateProfile.Name)"
            }
        }
        catch {
            Write-Verbose "$QualityUpdateProfileDisplayName - Failed to restore Windows Quality Update Profile" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreWindowsQualityUpdateProfile -Path "C:\temp\Intunerestore"