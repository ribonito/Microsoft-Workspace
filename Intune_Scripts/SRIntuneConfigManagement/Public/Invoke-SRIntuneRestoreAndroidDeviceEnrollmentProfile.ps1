function Invoke-SRIntuneRestoreAndroidDeviceEnrollmentProfile {
    <#
    .SYNOPSIS
    Restore Intune Android Device Enrollment Profile
    
    .DESCRIPTION
    Restore Intune Android Device Enrollment Profile from JSON files in the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreAndroidDeviceEnrollmentProfile -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Android Device Enrollment Profiles")) {
        Write-Warning "Folder '$Path\Android Device Enrollment Profiles' doesn't exist. Skipping restore of Android Device Enrollment Profile"
        Return
    }

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all assignment filters
    $Profiles = Get-ChildItem -Path "$path\Android Device Enrollment Profiles\*" -Include *.json
    
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

#        if ($SameTenant) {
            # We do a full restore including enrollment token
#            $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id,createdDateTime,lastModifiedDateTime,accountId,enrollmentTokenUsageCount,enrolledDeviceCount | ConvertTo-Json -Depth 10
#        } else {
            # We can't restore enrollment token. We remove the token from the request body and a new one will be generated for this tenant
            $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id,createdDateTime,lastModifiedDateTime,accountId,enrollmentTokenUsageCount,enrolledDeviceCount,tokenValue,qrCodeContent,tokenCreationDateTime,qrCodeImage,tokenExpirationDateTime | ConvertTo-Json -Depth 10
#        }

        # Restore the profile
        try {
            $Uri = "$ApiVersion/deviceManagement/androidDeviceOwnerEnrollmentProfiles"
            $response = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop

            if ($Response){
                #Create json for configuring DEVICE POLICY CONTROLLER for Google zero touch
                $GoogleZt = @{
                    "android.app.extra.PROVISIONING_DEVICE_ADMIN_COMPONENT_NAME" = "com.google.android.apps.work.clouddpc/.receivers.CloudDeviceAdminReceiver"
                    "android.app.extra.PROVISIONING_DEVICE_ADMIN_SIGNATURE_CHECKSUM" = "I5YvS0O5hXY46mb01BlRjq4oJJGs2kuUcHvVkAPEXlg"
                    "android.app.extra.PROVISIONING_DEVICE_ADMIN_PACKAGE_DOWNLOAD_LOCATION" = "https://play.google.com/managed/downloadManagingApp?identifier=setup"
                    "android.app.extra.PROVISIONING_ADMIN_EXTRAS_BUNDLE"= @{
                        "com.google.android.apps.work.clouddpc.EXTRA_ENROLLMENT_TOKEN" = "$($response.tokenValue)"
                   }
                }
            }            

            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Android Device Enrollment Profiles"
                "Name"   = $ProfileDisplayName
                "Path"   = "Android Device Enrollment Profiles\$($Profile.Name)"
            }

            Write-Output "Google Zero Touch DEVICE POLICY CONTROLLER json content:"
            $GoogleZt | ConvertTo-Json -Depth 10
        }
        catch {
            Write-Verbose "$ProfileDisplayName - Failed to restore Android Device Enrollment Profile" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreAndroidDeviceEnrollmentProfile -Path "C:\temp\Intunerestore"