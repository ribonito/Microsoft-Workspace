function Invoke-SRIntuneRestoreWindowsFeatureUpdateProfile {
    <#
    .SYNOPSIS
    Restore Intune Windows Feature Update Profile
    
    .DESCRIPTION
    Restore Intune Windows Feature Update Profile from JSON files
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreWindowsFeatureUpdateProfile -Path "C:\temp"
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
    $FeatureUpdateProfiles = Get-ChildItem -Path "$path\Windows Feature Update Profiles\*" -Include *.json
    
    foreach ($FeatureUpdateProfile in $FeatureUpdateProfiles) {
        $FeatureUpdateProfileContent = Get-Content -LiteralPath $FeatureUpdateProfile.FullName -Raw
        $FeatureUpdateProfileDisplayName = ($FeatureUpdateProfileContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $FeatureUpdateProfileContent | ConvertFrom-Json
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
        # Restore the device configuration
        #$requestBody
        try {
            $Uri = "$ApiVersion/deviceManagement/windowsFeatureUpdateProfiles"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Windows Feature Update Profile"
                "Name"   = $FeatureUpdateProfileDisplayName
                "Path"   = "Windows Feature Update Profiles\$($FeatureUpdateProfile.Name)"
            }
        }
        catch {
            Write-Verbose "$FeatureUpdateProfileDisplayName - Failed to restore Windows Feature Update Profile" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreWindowsFeatureUpdateProfile -Path "C:\temp\Intunerestore"