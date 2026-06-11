<#
.SYNOPSIS
    M365-002 | M365 Assessment - Exchange Distribution List Members Export.

.DESCRIPTION
    Connects to Exchange Online and exports the full membership of all
    Distribution Lists (DLs) in the tenant to a CSV file.

    Output columns per member:
        - GroupName
        - GroupEmail (Primary SMTP)
        - Member (display name)
        - EmailAddress (member Primary SMTP)
        - RecipientType

    Useful for DL audits, migration planning (DL → M365 Group), and governance reviews.

.PRODUCT
    Exchange Online

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    .\M365-002_DL-Members-Export.ps1

.NOTES
    - Module: ExchangeOnlineManagement
    - Requires "Exchange Administrator" role or "View-Only Recipients" at minimum
    - Output file: C:\Temp\DL-Members.csv
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$CSVFilePath = "C:\Temp\DL-Members_$(Get-Date -Format 'yyyyMMdd').csv"
#endregion

#region ── Connection ─────────────────────────────────────────────────────────
Try {
    Import-Module ExchangeOnlineManagement
    Connect-ExchangeOnline -ShowBanner:$false

    #region ── Collect Distribution Group Memberships ─────────────────────────
    $Result            = @()
    $DistributionGroups = Get-DistributionGroup -ResultSize Unlimited
    $GroupsCount        = $DistributionGroups.Count
    $Counter            = 1

    $DistributionGroups | ForEach-Object {
        Write-Progress `
            -Activity  "Processing Distribution List: $($_.DisplayName)" `
            -Status    "$Counter of $GroupsCount completed" `
            -PercentComplete (($Counter / $GroupsCount) * 100)

        $Group = $_
        Get-DistributionGroupMember -Identity $Group.Name -ResultSize Unlimited |
            ForEach-Object {
                $member  = $_
                $Result += New-Object PSObject -Property @{
                    GroupName     = $Group.Name
                    GroupEmail    = $Group.PrimarySmtpAddress
                    Member        = $Member.Name
                    EmailAddress  = $Member.PrimarySmtpAddress
                    RecipientType = $Member.RecipientType
                }
            }
        $Counter++
    }
    #endregion

    #region ── Export ─────────────────────────────────────────────────────────
    $Result | Export-CSV $CSVFilePath -NoTypeInformation -Encoding UTF8
    Write-Host "Export complete: $($Result.Count) member entries → $CSVFilePath" -ForegroundColor Green
    #endregion
}
Catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
#endregion
