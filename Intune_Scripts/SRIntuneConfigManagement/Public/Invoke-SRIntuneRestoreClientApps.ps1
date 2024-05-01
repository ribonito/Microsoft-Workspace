function Invoke-SRIntuneRestoreClientApps {
    <#
    .SYNOPSIS
    Restore Intune applications
    
    .DESCRIPTION
    Restore Intune applications from JSON files per Device Compliance Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located
    
    .EXAMPLE
    Invoke-SRIntuneRestoreClientApps -Path "C:\temp" -RestoreById $true
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

    # Get all applications
    $ClientApps = Get-ChildItem -Path "$Path\Client Apps" -File -Include *.json
    foreach ($ClientApp in $ClientApps) {
        $ClientAppContent = Get-Content -LiteralPath $ClientApp.FullName -Raw
        $ClientAppDisplayName = ($ClientAppContent | ConvertFrom-Json).displayName
        $ClientAppType = ($ClientAppContent | ConvertFrom-Json).'@odata.type'

        # Win32 LOB, MSFB and Android managed store app restore is currently not working
        if ($ClientAppType -ne "#microsoft.graph.win32LobApp" -and $ClientAppType -ne "#microsoft.graph.microsoftStoreForBusinessApp" -and $ClientAppType -ne "#microsoft.graph.androidManagedStoreApp") {

            # Remove properties that are not available for creating a new application
            $requestBodyObject = $ClientAppContent | ConvertFrom-Json
            $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id,createdDateTime,lastModifiedDateTime,version,'@odata.context',uploadState,appIdentifier,publishingState,usedLicenseCount,totalLicenseCount,productKey,licenseType,packageIdentityName | ConvertTo-Json -Depth 100

            # Restore the Device Compliance Policy
            try {
                $Uri = "$ApiVersion/deviceAppManagement/mobileApps"
                $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
                [PSCustomObject]@{
                    "Action" = "Restore"
                    "Type"   = "Mobile Application"
                    "Name"   = $ClientAppDisplayName
                    "Path"   = "Client Apps\$($ClientApp.Name)"
                }
            }
            catch {
                Write-Verbose "$($ClientApp.Name) - Failed to restore Application." -Verbose
                Write-Error $_ -ErrorAction Continue
            }
        }
    }
}

Invoke-SRIntuneRestoreClientApps -Path "C:\temp\Intunerestore"