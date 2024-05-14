function Get-SRAssignedFilterId {
    <#
    .SYNOPSIS
    Get filter id from name
     
    .DESCRIPTION
    Get filter id from name
     
    .PARAMETER FilterName
    String. Name of the filter
     
    .EXAMPLE
    Get-SRAssignedFilterId -FilterName "iOS managed"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilterName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $QueryFilter = "?`$select=id,displayName"

    # Get the group id passing the name
    $Uri = "$ApiVersion/deviceManagement/assignmentFilters$QueryFilter"
    $FilterId = $($(Invoke-MgGraphRequest -Uri $Uri).Value | Where-Object {$_.displayName -eq $FilterName}).id
    Return $FilterId
}

#Get-SRAssignedFilterId -FilterName "SRMW-iOS-Filter-Managed"