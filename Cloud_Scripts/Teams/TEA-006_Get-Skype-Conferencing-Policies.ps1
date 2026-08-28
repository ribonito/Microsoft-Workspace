<#
.SYNOPSIS
    TEA-006 | Export Skype for Business / Microsoft Teams Conferencing Policies.

.DESCRIPTION
    PowerShell script that reads Skype for Business (now Microsoft Teams) conferencing policies from 
    an Office 365 tenant, dynamically maps all policy properties, and exports the data to a CSV file.

.PRODUCT
    Skype for Business / Microsoft Teams

.ORIGINAL_AUTHOR
    Martina Grom - atwork.at

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-006 classification)

.VERSION
    1.0

.NOTES
    Name: TEA-006_Get-Skype-Conferencing-Policies.ps1
    Requires: Skype for Business Online PowerShell module (or MicrosoftTeams module).
#>

#region ── Main Program ───────────────────────────────────────────────────────
# Connect to your tenant first before running this script!
$separator = ","
$ignorefields = "XsAnyElements,XsAnyAttributes,PSComputerName,RunspaceId,PSShowComputerName,Element,ScopeClass,Anchor,Identity,TypedIdentity"

# get all policies first
$policies = Get-CsConferencingPolicy | Select-Object Identity

function GetHeader ([string]$policy, $properties) {
    $p = "`"Identity`"$separator"
    $properties.PSObject.Properties | ForEach-Object {
        $propname = $_.Name.ToString()
        if ($ignorefields -notmatch $propname) {
            $p += "`"$propname`"$separator"
        }
    }
    $p += [Environment]::NewLine
    return $p
}

function GetProperties ([string]$policy, $properties) {
    $p = "`"$policy`"$separator"
    $properties.PSObject.Properties | ForEach-Object {
        $propname = $_.Name.ToString()
        $propvalue = $_.Value
        if ($ignorefields -notmatch $propname) {
            if ($propvalue -and $propvalue.ToString().StartsWith("<")) {
                $propvalue = "[XML]"
            }
            $p += "`"$propvalue`"$separator"
        }
    }
    $p += [Environment]::NewLine
    return $p
}

$out = ''
$i = 0
foreach ($policy in $policies) { 
    $i++
    Write-Output $policy.Identity

    # read all properties per policy
    $properties = Get-CsConferencingPolicy -Identity $policy.Identity 

    if ($i -eq 1) { 
        # create the header only once
        $out += GetHeader $policy.Identity $properties
    }
    # read the properties and values
    $out += GetProperties $policy.Identity $properties
}

Out-File -FilePath .\skypepolicies.csv -InputObject $out
Write-Host "Done, check .\skypepolicies.csv and use Excel with Data filter for finding the desired policy."
#endregion
