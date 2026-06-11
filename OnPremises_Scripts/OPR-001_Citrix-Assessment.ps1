<#
.SYNOPSIS
    OPR-001 | On-Premises - Citrix XenApp/XenDesktop 7.x Inventory.

.DESCRIPTION
    Retrieves the published application inventory from a Citrix XenApp/XenDesktop 7.x controller
    and exports it to a CSV file.

.PRODUCT
    Citrix XenApp / XenDesktop 7.x

.AUTHOR
    Pradeep Raju
    Josep Canas - M365 Solutions Architect (OPR-001 classification & template)

.VERSION
    1.1

.EXAMPLE
    .\OPR-001_Citrix-Assessment.ps1
    (You will be prompted for sender and recipient email addresses)

.NOTES
    - Requires Citrix PowerShell Snapins installed on the execution machine.
    - Exports application inventory to C:\temp\Citrix7.8_ApplicationInventory.csv.
#>

#region ── Connection & Inputs ────────────────────────────────────────────────
$from = Read-Host "Enter Sender Email ID"
$sendto = Read-Host "Enter Recipient Email ID"
$subj = Read-Host "Enter email subject"

Add-PSSnapin Citrix*
#endregion

#region ── Directory Setup ────────────────────────────────────────────────────
if (-not (Test-Path "C:\temp")) {
    New-Item -ItemType Directory -Path "C:\temp" -Force | Out-Null
}
Set-Location "C:\temp"
Remove-Item -Path "Citrix7.8_*.csv" -ErrorAction SilentlyContinue
#endregion

#region ── Collect Application Inventory ──────────────────────────────────────
Get-BrokerApplication | 
    Select-Object ApplicationName, Enabled, AdminFolder, ClientFolder, CommandLineExecutable, WorkingDirectory,
                  @{Name='AssociatedUserFullNames';Expression={[string]::join(";",($_.AssociatedUserFullNames))}} | 
    Export-Csv -Path "C:\temp\Citrix7.8_ApplicationInventory.csv" -NoTypeInformation
#endregion

#region ── Collect Desktop Inventory (Optional) ───────────────────────────────
# Get-BrokerEntitlementPolicyRule | Select Name, includedusers, Enabled | Format-Table -Wrap | Out-File c:\temp\Citrix7.8_PublisheddesktopInventory.csv
#endregion

#region ── Email Report (Optional) ────────────────────────────────────────────
# Send-MailMessage -From $from -To $sendto -Smtp $smtp -Subject $subj -Body "Please find the report" -Attachment "C:\temp\Citrix7.8_*.csv"
#endregion
