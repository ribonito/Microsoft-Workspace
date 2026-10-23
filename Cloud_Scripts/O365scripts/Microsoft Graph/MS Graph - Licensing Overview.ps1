<#
.SYNOPSIS
    Audits subscribed Microsoft 365 licensing SKUs and included service plans via Microsoft Graph.

.DESCRIPTION
    Connects to Microsoft Graph using the Microsoft.Graph.Identity.Partner module, queries all
    subscribed licensing SKUs (SubscribedSku) in the tenant, maps individual service plans (ServicePlans),
    and exports an inventory of SKU part numbers, plan IDs, and friendly display names to CSV.

.PARAMETER ExportPath
    Destination file path for the licensing CSV report. Defaults to user desktop.

.NOTES
    Requires Microsoft.Graph PowerShell module with Organization.Read.All scope.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\MS Graph - Licensing Overview.ps1
    Queries Microsoft Graph for tenant SKUs and displays service plan mapping.

.LINK
    https://learn.microsoft.com/powershell/microsoftgraph/overview
    https://learn.microsoft.com/graph/api/subscribedsku-list
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ExportPath = "$env:USERPROFILE\Desktop\M365LicensingOverview_$((Get-Date -Format 'yyyyMMdd_HHmmss')).csv"
)

# Connect to Microsoft Graph
Import-Module Microsoft.Graph.Identity.Partner -ErrorAction SilentlyContinue
Connect-MgGraph -Scopes "Organization.Read.All" -NoWelcome

Write-Host "Querying Subscribed SKUs via Microsoft Graph..." -ForegroundColor Cyan

$ListSkus = Get-MgSubscribedSku -All -ErrorAction Stop
$ReportPlans = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($sku in $ListSkus) {
    Write-Host "Auditing SKU: $($sku.SkuPartNumber) (Prepaid Units: $($sku.PrepaidUnits.Enabled))" -ForegroundColor Yellow

    foreach ($plan in $sku.ServicePlans) {
        $ReportPlans.Add([PSCustomObject]@{
            SkuPartNumber      = $sku.SkuPartNumber
            SkuId              = $sku.SkuId
            ServicePlanName    = $plan.ServicePlanName
            ServicePlanId      = $plan.ServicePlanId
            ProvisioningStatus = $plan.ProvisioningStatus
        })
    }
}

Write-Host "`n=== Licensing SKU & Service Plan Summary ===" -ForegroundColor Green
$ReportPlans | Select-Object -Unique SkuPartNumber, ServicePlanName | Format-Table -AutoSize

if (-not [string]::IsNullOrWhiteSpace($ExportPath)) {
    $ReportPlans | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding utf8
    Write-Host "Licensing report successfully exported to: $ExportPath" -ForegroundColor Green
}