function Invoke-SRIntuneRestoreAssignmentFilter {
    <#
    .SYNOPSIS
    Restore Intune assignment filters
    
    .DESCRIPTION
    Restore Intune assignment filters from JSON files in the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER Assignments
    Restores assignments located in the assignments subfolder
    
    .EXAMPLE
    Invoke-SRIntuneRestoreAssignmentFilter -Path "C:\temp" -Assignments
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

    # Get all assignment filters
    $Profiles = Get-ChildItem -Path "$path\Assignment Filters\*" -Include *.json
    
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

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id,createdDateTime,lastModifiedDateTime,version,Payloads | ConvertTo-Json -Depth 10

        # Restore the assignment filter
        try {
            $Uri = "$ApiVersion/deviceManagement/assignmentFilters"
            $response = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Assignment filter"
                "Name"   = $ProfileDisplayName
                "Path"   = "Device Configurations\$($Profile.Name)"
            }
        }
        catch {
            Write-Verbose "$ProfileDisplayName - Failed to restore Assignment filter" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreAssignmentFilter -Path "C:\temp\Intunerestore"