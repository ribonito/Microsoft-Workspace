<#
.SYNOPSIS
    Searches Microsoft 365 and Exchange Online for duplicate or conflicting email addresses.

.DESCRIPTION
    Audits Exchange Online recipients, distribution groups, mail contacts, and Microsoft Entra ID
    users (including soft-deleted accounts in the recycle bin) to locate any object utilizing a
    specified target email address or proxy address. Essential for resolving delivery conflicts
    or proxy address clashes during provisioning.

.PARAMETER EmailAddress
    The SMTP email address or alias to locate across all directory object types.

.EXAMPLE
    .\Search-EmailAddress.ps1 -EmailAddress "john.doe@contoso.com"
    Searches mailboxes, distribution groups, contacts, and Entra users for the specified address.

.NOTES
    Author: Josep Canas - M365 Solutions Architect
    Requires ExchangeOnlineManagement and optionally MSOnline / Microsoft.Graph modules.

.LINK
    https://learn.microsoft.com/powershell/module/exchange/get-recipient
    https://learn.microsoft.com/powershell/module/exchange/get-distributiongroup
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Specify the email address to locate.")]
    [string]$EmailAddress = "user@domain.com"
)

if ([string]::IsNullOrWhiteSpace($EmailAddress)) {
    Write-Warning "No email address provided for search."
    return
}

Write-Host "Searching for recipient objects with address: $EmailAddress..." -ForegroundColor Cyan

# 1. Exchange Online Mailboxes and Recipients
try {
    $ListRecipients = Get-Recipient -ResultSize Unlimited -Filter "EmailAddresses -like '$EmailAddress' -or PrimarySmtpAddress -eq '$EmailAddress'" -ErrorAction Stop
    if ($ListRecipients) {
        Write-Host "Found $(($ListRecipients | Measure-Object).Count) recipient(s) in Exchange Online:" -ForegroundColor Yellow
        $ListRecipients | Format-Table DisplayName, UserPrincipalName, RecipientTypeDetails, PrimarySmtpAddress -AutoSize
    }
} catch {
    Write-Warning "Could not query Get-Recipient. Ensure you are connected to Exchange Online."
}

# 2. Distribution and Mail-Enabled Groups
try {
    $ListGroups = Get-DistributionGroup -Filter "EmailAddresses -like '$EmailAddress' -or PrimarySmtpAddress -eq '$EmailAddress'" -ErrorAction SilentlyContinue
    if ($ListGroups) {
        Write-Host "Found $(($ListGroups | Measure-Object).Count) group(s):" -ForegroundColor Yellow
        $ListGroups | Format-Table DisplayName, PrimarySmtpAddress, GroupType -AutoSize
    }
} catch {}

# 3. Mail Contacts
try {
    $ListContacts = Get-MailContact -Filter "EmailAddresses -like '$EmailAddress' -or ExternalEmailAddress -eq '$EmailAddress'" -ErrorAction SilentlyContinue
    if ($ListContacts) {
        Write-Host "Found $(($ListContacts | Measure-Object).Count) contact(s):" -ForegroundColor Yellow
        $ListContacts | Format-Table DisplayName, ExternalEmailAddress -AutoSize
    }
} catch {}

# 4. Soft-deleted / Active Entra Users (MSOnline if available)
if (Get-Command -Name Get-MsolUser -ErrorAction SilentlyContinue) {
    try {
        $ListMsolUsers = Get-MsolUser -All -SearchString $EmailAddress -ErrorAction SilentlyContinue
        if ($ListMsolUsers) {
            Write-Host "Found $(($ListMsolUsers | Measure-Object).Count) active MSOnline user(s):" -ForegroundColor Yellow
            $ListMsolUsers | Format-Table DisplayName, UserPrincipalName, IsLicensed -AutoSize
        }

        $ListMsolDeletedUsers = Get-MsolUser -ReturnDeletedUsers -ErrorAction SilentlyContinue |
            Where-Object { $_.UserPrincipalName -eq $EmailAddress -or $_.ProxyAddresses -like "*$EmailAddress*" }
        if ($ListMsolDeletedUsers) {
            Write-Host "Found $(($ListMsolDeletedUsers | Measure-Object).Count) soft-deleted user(s) in Recycle Bin:" -ForegroundColor Red
            $ListMsolDeletedUsers | Format-Table DisplayName, UserPrincipalName, SoftDeletionTimestamp -AutoSize
        }
    } catch {}
}
