<#
.SYNOPSIS
    M365-007 | M365 Assessment - Export M365 Licensing SKUs and Service Plans to CSV via Microsoft Graph.

.DESCRIPTION
    Uses the Microsoft Graph PowerShell SDK to extract all licensing SKUs and service plans
    in the tenant and maps them to their human-readable display names.

    Steps:
        1. Downloads the Microsoft licensing reference CSV from your local C:\temp folder
           (from: https://docs.microsoft.com/azure/active-directory/enterprise-users/licensing-service-plan-reference)
        2. Retrieves all subscribed SKUs in the tenant
        3. Exports SKU data with friendly display names to: C:\temp\SkuDataComplete.csv
        4. Exports service plan data to: C:\temp\ServicePlanDataComplete.csv

    Prerequisite: Download the product names CSV from Microsoft and place it in C:\temp before running.

.PRODUCT
    Microsoft 365 Licensing / Microsoft Graph

.ORIGINAL_AUTHOR
    Practical365.com
    Reference: https://practical365.com/create-licensing-report-microsoft365-tenant/
    Script: CreateCSVFilesForSKUsAndServicePlans.PS1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (M365-007 classification & English header)

.VERSION
    1.1

.NOTES
    - Module: Microsoft.Graph.Identity.DirectoryManagement (Get-MgSubscribedSku)
    - Required scope: Directory.Read.All
    - Pre-download the licensing reference CSV from Microsoft Docs before running
    - Output files: C:\temp\SkuDataComplete.csv, C:\temp\ServicePlanDataComplete.csv

.EXAMPLE
    .\M365-007_Licensing-SKU-Export.ps1
#>

# CreateCSVFilesForSKUsAndServicePlans.PS1
# See https://practical365.com/create-licensing-report-microsoft365-tenant/ for the article relating to this code

Connect-MgGraph -Scope Directory.Read.All -NoWelcome

#Import the Product names and service plan identifiers for licensing CSV file downloaded from https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference
# Remember to move the CSV file downloaded from Microsoft to c:\temp\
[array]$Identifiers = Import-Csv -Path "C:\temp\Product names and service plan identifiers for licensing.csv"
#select all SKUs with friendly display name
[array]$SKU_friendly = $identifiers | Select-Object GUID, String_Id, Product_Display_Name -Unique
#select the service plans with friendly display name 
[array]$SP_friendly = $identifiers | Select-Object Service_Plan_Id, Service_Plan_Name, Service_Plans_Included_Friendly_Names -Unique

# Get prpducts used in tenant
[Array]$Skus = Get-MgSubscribedSku

# Generate CSV of all product SKUs used in tenant
$Skus | Select-Object SkuId, SkuPartNumber, @{Name = "DisplayName"; Expression = { ($SKU_friendly | Where-object -Property GUID -eq $_.SkuId).Product_Display_Name } } | Export-Csv -NoTypeInformation c:\temp\SkuDataComplete.csv
# Generate list of all service plans used in SKUs in tenant
$SPData = [System.Collections.Generic.List[Object]]::new()
ForEach ($S in $Skus) {
    ForEach ($SP in $S.ServicePlans) {
        $SPLine = [PSCustomObject][Ordered]@{  
            ServicePlanId          = $SP.ServicePlanId
            ServicePlanName        = $SP.ServicePlanName
            #use 'Service_Plans_Included_Friendly_Names' from $SKU_friendly for 'ServicePlanDisplayName'
            ServicePlanDisplayName = ($SP_friendly | Where-Object { $_.Service_Plan_Id -eq $SP.ServicePlanId }).Service_Plans_Included_Friendly_Names | Select-Object -First 1 
        }
        $SPData.Add($SPLine)
    }
}
$SPData | Sort-Object ServicePlanId -Unique | Export-csv c:\Temp\ServicePlanDataComplete.csv -NoTypeInformation

