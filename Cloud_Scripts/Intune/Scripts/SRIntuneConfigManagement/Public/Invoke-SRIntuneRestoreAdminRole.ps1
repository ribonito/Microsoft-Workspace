function Invoke-SRIntuneRestoreAdminRole {
    <#
    .SYNOPSIS
    Restore Intune Admin role
    
    .DESCRIPTION
    Restore Intune Admin role from JSON files
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreAdminRole -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Admin Roles")) {
        Write-Warning "Folder '$Path\Admin Roles' doesn't exist. Skipping restore of Admin Roles"
        Return
    }

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all Admin roles
    $adminRoles = Get-ChildItem -Path "$Path\Admin Roles\*" -Include *.json
    foreach ($adminRole in $adminRoles) {
        $adminRoleContent = Get-Content -LiteralPath $adminRole.FullName -Raw
        $adminRoleDisplayName = ($adminRoleContent | ConvertFrom-Json).displayName
        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $adminRoleContent | ConvertFrom-Json
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

        # format the request body as required for restore.
        $roleperm = @()
        Foreach($item in $requestBodyObject.rolePermissions) {
            $tempobj = [PSCustomObject]@{}
            $tempobj | Add-Member -NotePropertyName '@odata.type' -NotePropertyValue "microsoft.graph.rolePermission"
            $resourceActionsFormatted = $item.resourceActions
            Foreach($act in $resourceActionsFormatted) {
                $act | Add-Member -NotePropertyName '@odata.type' -NotePropertyValue "microsoft.graph.resourceAction"
            }
            $tempobj | Add-Member -NotePropertyName 'resourceActions' -NotePropertyValue $resourceActionsFormatted
            $roleperm += $tempobj
        }

        $requestBodyObject.rolePermissions = $roleperm
        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, isBuiltInRoleDefinition,permissions | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the admin role
        try {
            $Uri = "$ApiVersion/deviceManagement/roleDefinitions"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Intune Admin role"
                "Name"   = $adminRoleDisplayName
                "Path"   = "Admin Roles\$($adminRole.Name)"
            }
        }
        catch {
            Write-Verbose "$adminRoleDisplayName - Failed to restore Intune admin role" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreAdminRole -Path "C:\temp\Intunerestore"