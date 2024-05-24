function Get-SRAppId {
    <#
    .SYNOPSIS
    Get app id from name
     
    .DESCRIPTION
    Get app id from name
     
    .PARAMETER FilterName
    String. Name of the app
     
    .EXAMPLE
    Get-SRAppId -AppName "iOS managed"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $QueryFilter = "?`$select=id,displayName"

    # Get the group id passing the name
    $Uri = "$ApiVersion/deviceAppManagement/mobileApps$QueryFilter"
    $AppId = $($(Invoke-MgGraphRequest -Uri $Uri).Value | Where-Object {$_.displayName -eq $AppName}).id
    Return $ScopeTagId
}

#Get-SRScopeTagId -AppName "SRMW"