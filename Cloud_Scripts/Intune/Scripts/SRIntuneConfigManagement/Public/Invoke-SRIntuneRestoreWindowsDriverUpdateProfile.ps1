function Invoke-SRIntuneRestoreWindowsDriverUpdateProfile {
    <#
    .SYNOPSIS
    Restore Intune Windows Drive rUpdate Profile
    
    .DESCRIPTION
    Restore Intune Windows Driver Update Profile from JSON files
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreWindowsDriverUpdateProfile -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Windows Driver Update Profiles")) {
        Write-Warning "Folder '$Path\Windows Driver Update Profiles' doesn't exist. Skipping restore of Windows Driver Update Profiles"
        Return
    }

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all device configurations
    $driverUpdateProfiles = Get-ChildItem -Path "$path\Windows Driver Update Profiles\*" -Include *.json
    
    foreach ($driverUpdateProfile in $driverUpdateProfiles) {
        $driverUpdateProfileContent = Get-Content -LiteralPath $driverUpdateProfile.FullName -Raw
        $driverUpdateProfileDisplayName = ($driverUpdateProfileContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $driverUpdateProfileContent | ConvertFrom-Json
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
            $Uri = "$ApiVersion/deviceManagement/windowsDriverUpdateProfiles"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Windows Driver Update Profile"
                "Name"   = $driverUpdateProfileDisplayName
                "Path"   = "Windows Driver Update Profiles\$($driverUpdateProfile.Name)"
            }
        }
        catch {
            Write-Verbose "$driverUpdateProfileDisplayName - Failed to restore Windows Driver Update Profile" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
        Start-Sleep -Seconds 5
    }
}

#Invoke-SRIntuneRestoreWindowsDriverUpdateProfile -Path "C:\temp\Intunerestore"