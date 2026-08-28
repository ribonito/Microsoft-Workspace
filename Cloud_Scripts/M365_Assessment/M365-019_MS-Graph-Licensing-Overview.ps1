<#
.SYNOPSIS
    M365-019 | Microsoft Graph Licensing and Service Plans Overview.

.DESCRIPTION
    PowerShell script that connects to Microsoft Graph, retrieves all subscribed licensing SKUs (subscriptions), 
    and generates an inventory report listing all assigned service plans and their corresponding IDs. 
    Exports results to CSV and console.

.PRODUCT
    Microsoft 365 / Microsoft Graph

.ORIGINAL_AUTHOR
    O365scripts Contributors (MS Graph - Licensing Overview classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Graph/MS%20Graph%20-%20Licensing%20Overview.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (M365-019 classification)

.VERSION
    1.0

.NOTES
    Name: M365-019_MS-Graph-Licensing-Overview.ps1
    Requires: Microsoft.Graph.Identity.DirectoryManagement module.
#>

#region ── Main Program ───────────────────────────────────────────────────────
# Connect to Microsoft Graph
Connect-MgGraph
Select-MgProfile -Name beta

# Pass through each SKU to list the service plans
[array]$ListSkus = Get-MgSubscribedSku
$ReportPlans = [System.Collections.Generic.List[object]]::new()

foreach ($Sku in $ListSkus) {
    foreach ($Plan in $Sku.ServicePlans) {
        Write-Host "Current Plan: " -NoNewline
        $Plan | Format-List
        
        $ReportLine = [PSCustomObject][ordered]@{
            ServicePlanId   = $Plan.ServicePlanId
            ServicePlanName = $Plan.ServicePlanName
            DisplayName     = $Plan.ServicePlanName	
        }
        $ReportPlans.Add($ReportLine)
    }
}

# Unique service plans list
$ReportPlans | Sort-Object ServicePlanId -Unique | Sort-Object ServicePlanName

# Subscription output
$ListSkus
# $ListSkus | Select-Object -First 1 *
# $ListSkus | Select-Object SkuPartNumber, SkuId | Out-GridView
# $ListSkus | Export-Csv -NoTypeInformation -Path "$env:USERPROFILE\Desktop\M365LicensingOverview.csv"

# Service plan output
$ReportPlans | Sort-Object ServicePlanId | Format-Table -AutoSize
#endregion