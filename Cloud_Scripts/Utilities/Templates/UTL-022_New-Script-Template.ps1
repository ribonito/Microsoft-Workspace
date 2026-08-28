<#
.SYNOPSIS
    UTL-022 | PowerShell Script Template.

.DESCRIPTION
    PowerShell script template outlining standard comment blocks, report building collection lists, 
    and export formatting patterns.

.PRODUCT
    Microsoft 365 / Templates

.ORIGINAL_AUTHOR
    O365scripts Contributors (New template classification)
    Reference: https://github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-022 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-022_New-Script-Template.ps1
#>

#region ── Main Program ───────────────────────────────────────────────────────
# Report builder example
$Report = [System.Collections.Generic.List[Object]]::new()
$ListX | ForEach-Object {
    $AttributeX = ""
    $AttributeX = $_.X

    $ReportLine = [PSCustomObject]@{
        X = $_
        Y = $AttributeX
        Z = ""
    }
    $Report.Add($ReportLine)
}

# View or export results
$Report | Format-List
$Report | Out-GridView
$Report | Export-Csv -Path "$env:USERPROFILE\Desktop\Export_$((Get-Date -Format "yyyyMMdd-hhmmss")).csv" -Encoding utf8 -NoTypeInformation
#endregion
