function Invoke-SRIntuneRestoreBrandingProfiles {
    <#
    .SYNOPSIS
    Restore Intune Branding Profiles
    
    .DESCRIPTION
    Restore Intune Branding Profiles from JSON files in the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreBrandingProfiles -Path "C:\temp" -Assignments
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
    if (-not (Test-Path "$Path\Branding profiles")) {
        Write-Warning "Folder '$Path\Branding profiles' doesn't exist. Skipping restore of Branding profiles"
        Return
    }

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all branding Profiles
    $Profiles = Get-ChildItem -Path "$path\Branding profiles\*" -Include *.json
    
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

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, landingPageCustomizedImage, lightBackgroundLogo, themeColorLogo, version | ConvertTo-Json -Depth 100

        # Restore the device configuration
        try {
            $Uri = "$ApiVersion/deviceManagement/intuneBrandingProfiles"
            $response = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            
            # If images are present in the json, add images to imported policy
            if($requestBodyObject.landingPageCustomizedImage -or $requestBodyObject.lightBackgroundLogo -or $requestBodyObject.themeColorLogo) {
                $Uri = "$ApiVersion/deviceManagement/intuneBrandingProfiles/$($response.id)"
                $requestBody = $requestBodyObject | Select-Object -Property landingPageCustomizedImage, lightBackgroundLogo, themeColorLogo | ConvertTo-Json -Depth 10
                $response = Invoke-MgGraphRequest -Method PATCH -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            }
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Branding Profile"
                "Name"   = $ProfileDisplayName
                "Path"   = "Branding profiles\$($Profile.Name)"
            }
        }
        catch {
            Write-Verbose "$ProfileDisplayName - Failed to restore Branding Profile" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
        Start-Sleep -Seconds 5
    }
}

#Invoke-SRIntuneRestoreBrandingPolicies -Path "C:\temp\Intunerestore"