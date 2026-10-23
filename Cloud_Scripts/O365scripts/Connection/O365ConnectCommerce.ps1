<#
.SYNOPSIS
    Connects to the Microsoft 365 Commerce PowerShell module (MSCommerce).

.DESCRIPTION
    Establishes an administrative session using the MSCommerce module to manage self-service
    purchases across Microsoft 365 products (Power Apps, Power Automate, Power BI, Visio, etc.).
    Verifies module installation and initiates Connect-MSCommerce.

.NOTES
    Requires the MSCommerce PowerShell module and Global or Billing Administrator privileges.
    Self-service purchasing policies apply per-product SKU.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\O365ConnectCommerce.ps1
    Imports the MSCommerce module and initiates interactive authentication.

.LINK
    https://learn.microsoft.com/microsoft-365/commerce/subscriptions/manage-self-service-purchases-admins
    https://learn.microsoft.com/microsoft-365/commerce/subscriptions/allowselfservicepurchase-powershell
#>

[CmdletBinding()]
param ()

# Ensure MSCommerce module is available
if (-not (Get-Module -ListAvailable -Name MSCommerce)) {
    Write-Host "Installing MSCommerce module..." -ForegroundColor Yellow
    Install-Module MSCommerce -AllowClobber -Force -Confirm:$false -Scope CurrentUser
}

Import-Module MSCommerce
Write-Host "Connecting to Microsoft 365 Commerce..." -ForegroundColor Cyan
Connect-MSCommerce

Write-Host "Connected to MSCommerce. Checking current self-service purchase policies:" -ForegroundColor Green
Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase | Format-Table -AutoSize
