<#
.SYNOPSIS
    EXO-006 | Partner Center - Query Customer and Billing Information via PartnerCenter Module.

.DESCRIPTION
    Uses the PartnerCenter PowerShell module to query Microsoft CSP (Cloud Solution Provider)
    partner data, including:
        - Partner agreement and billing profile
        - List of managed customers
        - Customer billing profiles
        - Bulk export of billing contacts from a CSV of customer tenant IDs

    Useful for MSPs and CSP partners managing multiple Microsoft 365 tenants.

.PRODUCT
    Partner Center / Microsoft CSP

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    # First-time setup (run once):
    # Install-Module -Name PartnerCenter -AllowClobber
    # Import-Module PartnerCenter

.EXAMPLE
    .\EXO-006_PartnerCenter-CustomerQuery.ps1
#>

#region ── Module & Connection ────────────────────────────────────────────────
# Note: Install-Module -Name PartnerCenter -AllowClobber  (first time only)
Import-Module PartnerCenter
Connect-PartnerCenter
#endregion

#region ── Partner Information ───────────────────────────────────────────────
Get-PartnerAgreementDetail
Get-PartnerBillingProfile
#endregion

#region ── Customer List ──────────────────────────────────────────────────────
Get-PartnerCustomer
#endregion

#region ── Single Customer Lookup ────────────────────────────────────────────
# Replace with the actual customer tenant ID
Get-PartnerCustomer -CustomerId '56299af2-fcd5-4085-9320-d6c7fdb9db95'
Get-PartnerCustomerBillingProfile -CustomerId '2c0d789f-2311-4d29-83c5-395a89052a25' | Format-List
#endregion

#region ── Bulk Export: Billing Contacts from CSV ────────────────────────────
# CSV must have a column named: CustomerTenantId
# Output: C:\temp\Processed-CustomerAgreementRecords.csv
Import-Csv "C:\temp\CustomerAgreementRecords.csv" |
    ForEach-Object {
        Get-PartnerCustomerBillingProfile -CustomerId $_.CustomerTenantId -ErrorAction SilentlyContinue
    } |
    Select-Object -Property Email, FirstName, LastName |
    Export-Csv "C:\temp\Processed-CustomerAgreementRecords.csv" -NoTypeInformation -Verbose
#endregion
