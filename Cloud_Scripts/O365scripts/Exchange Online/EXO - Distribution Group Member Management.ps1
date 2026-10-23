<#
.SYNOPSIS
    Interactively adds selected users to one or multiple Exchange Online distribution groups.

.DESCRIPTION
    Presents an interactive GUI selection (Out-GridView) for administrators to pick target
    distribution groups and user mailboxes, then systematically assigns the selected users
    as members of each chosen distribution group.

.NOTES
    Requires ExchangeOnlineManagement module.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - Distribution Group Member Management.ps1
    Opens Out-GridView pickers to select groups and users, then performs the membership additions.

.LINK
    https://learn.microsoft.com/powershell/module/exchange/add-distributiongroupmember
    https://learn.microsoft.com/microsoft-365/admin/manage/create-distribution-lists
#>

[CmdletBinding()]
param ()

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline

Write-Host "Select target Distribution Groups:" -ForegroundColor Cyan
$ListDG = Get-DistributionGroup -RecipientTypeDetails MailUniversalDistributionGroup -ResultSize Unlimited |
    Out-GridView -Title "Select one or more Distribution Groups (hold Ctrl)" -PassThru

if (-not $ListDG) {
    Write-Warning "No distribution groups selected. Exiting."
    return
}

Write-Host "Select users to add as members:" -ForegroundColor Cyan
$ListUsers = Get-EXOMailbox -RecipientTypeDetails UserMailbox -ResultSize Unlimited |
    Out-GridView -Title "Select one or more Users to add (hold Ctrl)" -PassThru

if (-not $ListUsers) {
    Write-Warning "No users selected. Exiting."
    return
}

# Add selected users to each chosen group
foreach ($dg in $ListDG) {
    Write-Host "`nAdding members to group: $($dg.DisplayName)" -ForegroundColor Yellow
    foreach ($user in $ListUsers) {
        try {
            Add-DistributionGroupMember -Identity $dg.DistinguishedName -Member $user.DistinguishedName -ErrorAction Stop
            Write-Host " + Added $($user.DisplayName) ($($user.PrimarySmtpAddress))" -ForegroundColor Green
        } catch {
            Write-Warning " Could not add $($user.DisplayName) to $($dg.DisplayName): $_"
        }
    }
}

Write-Host "`nDistribution group member assignment process completed." -ForegroundColor Green
