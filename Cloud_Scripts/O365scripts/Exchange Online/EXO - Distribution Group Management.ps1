<#
.SYNOPSIS
    Exports a complete membership roster of all Exchange Online distribution groups to CSV.

.DESCRIPTION
    Connects to Exchange Online and audits every distribution group, querying its members,
    primary SMTP addresses, and recipient type details. Produces a structured report and
    exports the findings to CSV for compliance and group lifecycle audits.

.PARAMETER ExportPath
    Destination file path for the exported CSV report. Defaults to user desktop.

.NOTES
    Requires ExchangeOnlineManagement module.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - Distribution Group Management.ps1
    Generates a full distribution group membership report and exports it to the desktop.

.LINK
    https://learn.microsoft.com/powershell/module/exchange/get-distributiongroup
    https://learn.microsoft.com/powershell/module/exchange/get-distributiongroupmember
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ExportPath = "$env:USERPROFILE\Desktop\list_dgmembers_$((Get-Date -Format 'yyyyMMdd_HHmmss')).csv"
)

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline

Write-Host "Querying all Distribution Groups in Exchange Online..." -ForegroundColor Cyan

$report = [System.Collections.Generic.List[PSCustomObject]]::new()
$list_dg = Get-DistributionGroup -ResultSize Unlimited
$count_dg = ($list_dg | Measure-Object).Count
$i = 1

foreach ($group in $list_dg) {
    Write-Progress -Activity "Auditing members of $($group.DisplayName)" -Status "$i of $count_dg groups processed" -PercentComplete (($i / $count_dg) * 100)
    
    $members = Get-DistributionGroupMember -Identity $group.DistinguishedName -ResultSize Unlimited -ErrorAction SilentlyContinue
    if ($members) {
        foreach ($member in $members) {
            $report.Add([PSCustomObject]@{
                GroupDisplayName    = $group.DisplayName
                GroupPrimarySmtp    = $group.PrimarySmtpAddress
                MemberDisplayName   = $member.DisplayName
                MemberPrimarySmtp   = $member.PrimarySmtpAddress
                MemberRecipientType = $member.RecipientType
            })
        }
    } else {
        $report.Add([PSCustomObject]@{
            GroupDisplayName    = $group.DisplayName
            GroupPrimarySmtp    = $group.PrimarySmtpAddress
            MemberDisplayName   = "[NO MEMBERS]"
            MemberPrimarySmtp   = $null
            MemberRecipientType = $null
        })
    }
    $i++
}

Write-Host "`nDistribution group audit completed. Total member entries: $($report.Count)" -ForegroundColor Green

if (-not [string]::IsNullOrWhiteSpace($ExportPath)) {
    $report | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding utf8
    Write-Host "Report exported to: $ExportPath" -ForegroundColor Green
}
