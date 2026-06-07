function Get-SRAssignedGroupId {
    <#
    .SYNOPSIS
    Get assigned AAD group id from name
     
    .DESCRIPTION
    Get assigned AAD group id from name
     
    .PARAMETER GroupName
    String. Name of the group
     
    .EXAMPLE
    Get-SRAssignedGroupId -GroupName "Intune Users"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$GroupName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $QueryFilter = "?`$filter=displayName eq '$GroupName'&select=id"
    # Get the group id passing the name
    $Uri = "$ApiVersion/groups$QueryFilter"
    $GroupId = $(Invoke-MgGraphRequest -Uri $Uri).Value.id
    Return $GroupId
}
