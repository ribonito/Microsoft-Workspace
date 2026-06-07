function Invoke-SRIntuneRestoreScopeTags {
    <#
    .SYNOPSIS
    Restore Intune scope tags
    
    .DESCRIPTION
    Restore Intune scope tags from JSON files in the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER Assignments
    Restores assignments located in the assignments subfolder
    
    .EXAMPLE
    Invoke-SRIntuneRestoreScopeTags -Path "C:\temp" -Assignments
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

    # Check if restore folder exists
    if (-not (Test-Path "$Path\Scope Tags")) {
        Write-Warning "Folder '$Path\Scope Tags' doesn't exist. Skipping restore of Scope Tags"
        Return
    }

    # Get all json files
    $Profiles = Get-ChildItem -Path "$path\Scope Tags\*" -Include *.json
    
    foreach ($Profile in $Profiles) {
        $ProfileContent = Get-Content -LiteralPath $Profile.FullName -Raw
        $ProfileDisplayName = ($ProfileContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating action
        $requestBodyObject = $ProfileContent | ConvertFrom-Json

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id | ConvertTo-Json -Depth 10

        # Restore the scope tag
        try {
            $Uri = "$ApiVersion/deviceManagement/roleScopeTags"
            $response = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Scope Tag"
                "Name"   = $ProfileDisplayName
                "Path"   = "Device Configurations\$($Profile.Name)"
            }
        }
        catch {
            Write-Verbose "$ProfileDisplayName - Failed to restore scope tag" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
        Start-Sleep -Seconds 5
    }
}

#Invoke-SRIntuneRestoreScopeTags -Path "C:\temp\Intunerestore"