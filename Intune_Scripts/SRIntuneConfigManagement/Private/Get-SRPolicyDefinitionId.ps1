function Get-SRPolicyDefinitionId {
    <#
    .SYNOPSIS
    Get Policy Definition id from name
     
    .DESCRIPTION
    Get Policy Definition id from name
     
    .PARAMETER FilterName
    String. Name of the app
     
    .EXAMPLE
    Get-SRPolicyDefinitionId -DefinitionName "iOS managed" -categoryPath "\Microsoft Edge"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DefinitionName,
        [Parameter(Mandatory = $true)]
        [string]$categoryPath,
        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $QueryFilter = "?`$filter=policyType eq 'admxIngested'&`$select=id,categoryPath,displayName"

    # Get the group id passing the name
    $Uri = "$ApiVersion/deviceManagement/groupPolicyDefinitions"
    $DefId = $($(Invoke-MgGraphRequest -Uri $Uri).Value | Where-Object {$_.displayName -eq $DefinitionName -and $_.categoryPath -eq $categoryPath}).id
    Return $DefId
}

#Get-SRPolicyDefinitionId -DefinitionName "Drive S" -categoryPath "\Network Drive Mappings"