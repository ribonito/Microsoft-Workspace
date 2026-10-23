<#
.SYNOPSIS
    Audits and permanently removes (purges) soft-deleted user accounts from Entra ID / Office 365.

.DESCRIPTION
    Queries user accounts in the Entra ID / Microsoft 365 Recycle Bin (soft-deleted users).
    Provides interactive GUI selection via Out-GridView and safe confirmation prompts to
    permanently purge deleted accounts from the directory (hard delete), preventing identity collisions.

.PARAMETER WhatIf
    Shows what would happen if the command runs without executing the permanent deletion.

.NOTES
    Requires MSOnline module and Global Administrator privileges.
    WARNING: Purged accounts cannot be recovered from the recycle bin once hard deleted.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\MSOL - Deleted User Management.ps1
    Prompts to select deleted users from a grid view and requires confirmation before purging.

.LINK
    https://learn.microsoft.com/powershell/module/msonline/remove-msoluser
    https://learn.microsoft.com/microsoft-365/admin/add-users/restore-user
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param ()

# Connect to MSOnline
Import-Module MSOnline -ErrorAction SilentlyContinue
Connect-MsolService

Write-Host "Querying soft-deleted users in the Microsoft 365 Recycle Bin..." -ForegroundColor Cyan

$deletedUsers = Get-MsolUser -All -ReturnDeletedUsers |
    Select-Object DisplayName, UserPrincipalName, ObjectId, SoftDeletionTimestamp

if (-not $deletedUsers) {
    Write-Host "No deleted users currently in the Recycle Bin." -ForegroundColor Green
    return
}

Write-Host "Found $(($deletedUsers | Measure-Object).Count) soft-deleted user(s)." -ForegroundColor Yellow

$selectedUsers = $deletedUsers |
    Out-GridView -Title "Select user(s) to PERMANENTLY purge from Recycle Bin" -PassThru

if ($selectedUsers) {
    Write-Host "`nWARNING: You are about to permanently purge the following users:" -ForegroundColor Red
    $selectedUsers | Format-Table DisplayName, UserPrincipalName, ObjectId -AutoSize

    $confirmation = Read-Host -Prompt "Type 'CONFIRM' to permanently remove these accounts"
    if ($confirmation -eq "CONFIRM") {
        foreach ($u in $selectedUsers) {
            if ($PSCmdlet.ShouldProcess($u.UserPrincipalName, "Permanently purge from Recycle Bin")) {
                Write-Host "Purging $($u.UserPrincipalName)..." -ForegroundColor Yellow
                Remove-MsolUser -ObjectId $u.ObjectId -RemoveFromRecycleBin -Force
                Write-Host "Account $($u.UserPrincipalName) purged." -ForegroundColor Green
            }
        }
    } else {
        Write-Host "Operation cancelled by user." -ForegroundColor Gray
    }
}
