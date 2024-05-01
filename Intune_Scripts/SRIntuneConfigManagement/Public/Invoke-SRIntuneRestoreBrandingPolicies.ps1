function Invoke-SRIntuneRestoreBrandingPolicies {
    <#
    .SYNOPSIS
    Restore Intune Branding Policies
    
    .DESCRIPTION
    Restore Intune Branding Policies from JSON files in the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER Assignments
    Restores assignments located in the assignments subfolder
    
    .EXAMPLE
    Invoke-SRIntuneRestoreBrandingPolicies -Path "C:\temp" -Assignments
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [switch]$Assigments,
        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Get all device configurations
    $Profiles = Get-ChildItem -Path "$path\Branding profiles" -File
    
    foreach ($Profile in $Profiles) {
        $ProfileContent = Get-Content -LiteralPath $Profile.FullName -Raw
        $ProfileDisplayName = ($ProfileContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating action
        $requestBodyObject = $ProfileContent | ConvertFrom-Json
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
                "Type"   = "Device Configuration"
                "Name"   = $deviceConfigurationDisplayName
                "Path"   = "Device Configurations\$($Profile.Name)"
            }
        }
        catch {
            Write-Verbose "$ProfileDisplayName - Failed to restore Branding policy" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreBrandingPolicies -Path "C:\temp\Intunerestore"