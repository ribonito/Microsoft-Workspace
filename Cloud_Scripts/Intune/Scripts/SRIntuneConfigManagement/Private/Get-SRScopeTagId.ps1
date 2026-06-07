function Get-SRScopeTagId {
    <#
    .SYNOPSIS
    Get filter id from name
     
    .DESCRIPTION
    Get filter id from name
     
    .PARAMETER FilterName
    String. Name of the filter
     
    .EXAMPLE
    Get-SRScopeTagId -ScopeTagName "iOS managed"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScopeTagName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $QueryFilter = "?`$select=id,displayName"

    # Get the group id passing the name
    $Uri = "$ApiVersion/deviceManagement/roleScopeTags$QueryFilter"
    $ScopeTagId = $($(Invoke-MgGraphRequest -Uri $Uri).Value | Where-Object {$_.displayName -eq $ScopeTagName}).id
    Return $ScopeTagId
}

#Get-SRScopeTagId -ScopeTagName "SRMW"