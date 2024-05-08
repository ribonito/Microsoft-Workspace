function Invoke-SRIntuneRestoreGroups {
    <#
    .SYNOPSIS
    Restore Entra ID groups
    
    .DESCRIPTION
    Restore Entra ID groups from JSON files in the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located
    
    .EXAMPLE
    Invoke-SRIntuneRestoreGroups -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Check if restore folder exists
    if (-not (Test-Path "$Path\Groups")) {
        Write-Warning "Folder '$Path\Groups' doesn't exist. Skipping restore of groups"
        Return
    }

    # Get all groups
    $Groups = Get-ChildItem -Path "$path\Groups\*" -Include *.json

    if ($SameTenant -and $Groups) {
        #Confirm restoration of groups
        $confirmation = Read-Host "You are restoring $($Groups.count) in the same tenant. Are you sure you want to do this? (y/n)"
        if ($confirmation -ne 'y') {
            return
        }        
    }
    
    foreach ($Group in $Groups) {
        $GroupContent = Get-Content -LiteralPath $Group.FullName -Raw
        $GroupDisplayName = ($GroupContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $GroupContent | ConvertFrom-Json
        # Set SupportsScopeTags to $false, because $true currently returns an HTTP Status 400 Bad Request error.
        if ($requestBodyObject.supportsScopeTags) {
            $requestBodyObject.supportsScopeTags = $false
        }

        $requestBodyObject.PSObject.Properties | Foreach-Object {
            if ($null -ne $_.Value) {
                if ($_.Value.GetType().Name -eq "DateTime") {
                    $_.Value = (Get-Date -Date $_.Value -Format s) + "Z"
                }
            }
        }

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id,visibility,mail,theme,preferredDataLocation,uniqueName,isManagementRestricted,classification,expirationDateTime,createdDateTime,createdByAppId,serviceProvisioningErrors,renewedDateTime,onPremisesLastSyncDateTime,proxyAddresses,isAssignableToRole,onPremisesProvisioningErrors,onPremisesNetBiosName,resourceProvisioningOptions,preferredLanguage,onPremisesObjectIdentifier,onPremisesSyncEnabled,onPremisesSamAccountName,resourceBehaviorOptions,infoCatalogs,deletedDateTime,organizationId,securityIdentifier,onPremisesDomainName,onPremisesSecurityIdentifier,creationOptions | ConvertTo-Json -Depth 100

        # Restore the device configuration
        try {
            $Uri = "$ApiVersion/groups"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Group"
                "Name"   = $GroupDisplayName
                "Path"   = "Groups\$($Group.Name)"
            }
        }
        catch {
            Write-Verbose "$GroupDisplayName - Failed to restore group" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreGroups -Path "C:\temp\Intunerestore"
