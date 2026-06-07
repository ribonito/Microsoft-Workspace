Install-Module -Name MSCommerce -Scope CurrentUser

Import-Module -Name MSCommerce

Connect-MSCommerce #log in here

$products = Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase | Where { $_.PolicyValue -eq "Enabled"}

foreach ($p in $products)

{

Update-MSCommerceProductPolicy -PolicyId AllowSelfServicePurchase -ProductId $p.ProductId -Enabled $False

}