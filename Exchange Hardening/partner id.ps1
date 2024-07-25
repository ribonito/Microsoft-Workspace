# Bellow 2 commented commands are required only once
 
# Install-Module -Name PartnerCenter -AllowClobber
# Import-Module PartnerCenter 
# Connect to partner center 
Connect-PartnerCenter
import-module partnercenter
 
Get-PartnerAgreementDetail

Get-PartnerBillingProfile



get-PartnerCustomer


Get-PartnerCustomer -CustomerId '56299af2-fcd5-4085-9320-d6c7fdb9db95' | select -ExpandProperty Name

Get-PartnerCustomerBillingProfile -CustomerId '2c0d789f-2311-4d29-83c5-395a89052a25'| fl


Import-csv “c:\temp\CustomerAgreementRecords.csv” | foreach { Get-PartnerCustomerBillingProfile -CustomerId $_.CustomerTenantId -ErrorAction SilentlyContinue } | Select-Object -Property Email, FirstName,LastName | Export-Csv c:\temp\Processed-CustomerAgreementRecords.csv -NoTypeInformation -Verbose
