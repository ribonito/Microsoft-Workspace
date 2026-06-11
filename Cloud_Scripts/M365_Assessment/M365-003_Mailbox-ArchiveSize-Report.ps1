<#
.SYNOPSIS
    M365-003 | M365 Assessment - Mailbox and Archive Size Report.

.DESCRIPTION
    Connects to Exchange Online and exports a report of all mailbox sizes
    (primary and archive) for all users in the tenant.

    Output columns per user:
        - User (UPN)
        - DisplayName
        - MailboxTypeDetail
        - TotalSize (GB)
        - ArchiveSize (total item size of the online archive)

    Useful for migration sizing, license planning (Exchange Plan 1 vs 2),
    and pre-migration capacity assessment.

.PRODUCT
    Exchange Online

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    .\M365-003_Mailbox-ArchiveSize-Report.ps1

.NOTES
    - Module: ExchangeOnlineManagement
    - Requires "Exchange Administrator" or "View-Only Recipients" role
    - Output file: C:\Temp\O365-Mailbox-<date>.csv
#>

#region ── Connection ─────────────────────────────────────────────────────────
Connect-ExchangeOnline -ShowBanner:$false
#endregion

#region ── Collect Mailbox Sizes ──────────────────────────────────────────────
$users        = Get-Mailbox -ResultSize Unlimited
$CustomResult = @()

foreach ($user in $users.UserPrincipalName) {
    $Mailbox          = Get-MailboxStatistics $user | Select-Object DisplayName, MailboxTypeDetail
    $MailboxStatistics = Get-MailboxStatistics $user |
        Select-Object @{
            Name       = "Total Size (GB)"
            Expression = {
                [math]::Round(
                    ($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","") / 1GB),
                    2
                )
            }
        }
    $Archive = Get-ExoMailboxStatistics -Archive -Identity $user |
        Select-Object DisplayName, TotalItemSize

    $CustomResult += [PSCustomObject]@{
        User              = $user
        DisplayName       = $Mailbox.DisplayName
        MailboxTypeDetail = $Mailbox.MailboxTypeDetail
        TotalSizeGB       = $MailboxStatistics."Total Size (GB)"
        ArchiveSize       = $Archive.TotalItemSize
    }
}
#endregion

#region ── Export ─────────────────────────────────────────────────────────────
$OutputPath = "C:\Temp\O365-Mailbox_$(Get-Date -Format 'yyyyMMdd').csv"
$CustomResult | Export-CSV $OutputPath -NoTypeInformation -Encoding UTF8
Write-Host "Report exported to: $OutputPath" -ForegroundColor Green
#endregion
