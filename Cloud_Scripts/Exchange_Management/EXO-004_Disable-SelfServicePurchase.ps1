<#
.SYNOPSIS
    EXO-004 | Exchange Online - Disable Self-Service Purchases for All Products.

.DESCRIPTION
    Iterates through all Microsoft 365 products that have the
    AllowSelfServicePurchase policy set to "Enabled" and disables it.

    This prevents end-users from purchasing Microsoft 365 add-on services
    (Power Platform, Project, Visio, etc.) on their own using a personal
    credit card, which bypasses IT procurement controls.

.PRODUCT
    Exchange Online / M365 Commerce (MSCommerce module)

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    .\EXO-004_Disable-SelfServicePurchase.ps1

.NOTES
    - Module: MSCommerce (Install-Module -Name MSCommerce -Scope CurrentUser)
    - Run with "Billing Administrator" or "Global Administrator"
    - The MSCommerce module does NOT support app-only authentication
#>

#region ── Module Setup ───────────────────────────────────────────────────────
Install-Module -Name MSCommerce -Scope CurrentUser
Import-Module  -Name MSCommerce
#endregion

#region ── Connection ─────────────────────────────────────────────────────────
Connect-MSCommerce
#endregion

#region ── Disable Self-Service Purchase for all enabled products ─────────────
$enabledProducts = Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase |
    Where-Object { $_.PolicyValue -eq "Enabled" }

Write-Output "Products with Self-Service Purchase enabled: $($enabledProducts.Count)"

foreach ($product in $enabledProducts) {
    Update-MSCommerceProductPolicy `
        -PolicyId  AllowSelfServicePurchase `
        -ProductId $product.ProductId `
        -Enabled   $false
    Write-Output "Disabled self-service purchase for: $($product.ProductDisplayName)"
}

Write-Output "All self-service purchases disabled."
#endregion
