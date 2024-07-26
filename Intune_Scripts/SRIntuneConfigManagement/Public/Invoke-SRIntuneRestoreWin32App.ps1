function Invoke-SRIntuneRestoreWin32App {
    <#
    .SYNOPSIS
    Restore Intune Win32 applications
    
    .DESCRIPTION
    Restore Intune Win32 applications from JSON files per Device Compliance Policy from the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located
    
    .EXAMPLE
    Invoke-SRIntuneRestoreWin32App -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [switch]$Assigments,
        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta",
        [parameter(Mandatory = $true)]
        [string]$TenantID
    )

    # Get all applications
    $ClientApps = Get-ChildItem -Path "$Path\Client Apps\*" -File -Include *.json
    foreach ($ClientApp in $ClientApps) {
        $ClientAppContent = Get-Content -LiteralPath $ClientApp.FullName -Raw
        $ClientAppDisplayName = ($ClientAppContent | ConvertFrom-Json).displayName
        $ClientAppType = ($ClientAppContent | ConvertFrom-Json).'@odata.type'

        # Filter Win32 LOB, MSFB and Android managed store app restore is currently not working
        if ($ClientAppType -eq "#microsoft.graph.win32LobApp") {
            # Check if intunewin file for the app exists in Content subfolder
            $ContentFileName = $(($ClientApp.Name).Replace('json','intunewin'))
            $ContentFilePath = "$Path\Client Apps\Content\$ContentFileName"
            if (-not (Test-Path "$ContentFilePath")) {
                Write-Verbose "$($ClientApp.Name) - Failed to restore Application. Missing the intunewin file for the app." -Verbose
                #Write-Error $_ -ErrorAction Continue
                Return
            }

            # Remove properties that are not available for creating a new application
            $requestBodyObject = $ClientAppContent | ConvertFrom-Json
            $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id,createdDateTime,lastModifiedDateTime,version,'@odata.context',uploadState,appIdentifier,publishingState,usedLicenseCount,totalLicenseCount,productKey,licenseType,packageIdentityName,size,isAssigned,dependentAppCount,committedContentVersion,supersedingAppCount,supersededAppCount #| ConvertTo-Json -Depth 10

            #Get a token from Graph session required by IntuneWin32App module functions
            Connect-MSIntuneGraph -TenantID $TenantID

            # Add new MSI Win32 app
            Add-IntuneWin32App -FilePath $ContentFilePath -Win32AppBody $requestBody #-Verbose

            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Mobile Application"
                "Name"   = $ClientAppDisplayName
                "Path"   = "Client Apps\$($ClientApp.Name)"
            }
            Start-Sleep -Seconds 15
        }
    }
}

#Invoke-SRIntuneRestoreWin32App -Path "C:\temp\Intunerestore"