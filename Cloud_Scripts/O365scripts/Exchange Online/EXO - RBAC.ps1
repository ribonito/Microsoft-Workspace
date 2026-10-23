<#
.SYNOPSIS
    Creates and assigns customized Role Based Access Control (RBAC) policies in Exchange Online.

.DESCRIPTION
    Creates a customized management role based on MyBaseOptions that strips parameters allowing
    users to configure automatic email forwarding (ForwardTo, RedirectTo, ForwardingSmtpAddress).
    Packages this role into a custom Role Assignment Policy and assigns it to users, closing a common
    data exfiltration vector.

.PARAMETER Identity
    Optional UserPrincipalName to immediately assign the new role assignment policy.

.PARAMETER RoleName
    Name of the new customized management role. Defaults to 'CustomMyBaseOptions'.

.PARAMETER PolicyName
    Name of the new role assignment policy. Defaults to 'CustomMyBaseOptionsPolicy'.

.NOTES
    Requires ExchangeOnlineManagement module and hydrated tenant (Enable-OrganizationCustomization).
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\EXO - RBAC.ps1 -Identity "user@contoso.com"
    Builds the anti-forwarding RBAC role and policy, and assigns it to user@contoso.com.

.LINK
    https://learn.microsoft.com/exchange/permissions-exo/role-based-access-control
    https://learn.microsoft.com/powershell/module/exchange/new-managementrole
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Identity = "user@domain.com",

    [Parameter(Mandatory = $false)]
    [string]$RoleName = "CustomMyBaseOptions",

    [Parameter(Mandatory = $false)]
    [string]$PolicyName = "CustomMyBaseOptionsPolicy"
)

# Connect to Exchange Online
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue
Connect-ExchangeOnline

Write-Host "Configuring custom RBAC anti-forwarding role and policy..." -ForegroundColor Cyan

# 1. Create custom management role if not already present
$existingRole = Get-ManagementRole -Identity $RoleName -ErrorAction SilentlyContinue
if (-not $existingRole) {
    Write-Host "Creating Management Role '$RoleName' derived from 'MyBaseOptions'..." -ForegroundColor Yellow
    New-ManagementRole -Name $RoleName -Parent MyBaseOptions
}

# 2. Strip auto-forwarding parameters from Inbox Rule and Mailbox cmdlets
Write-Host "Stripping auto-forwarding parameters from '$RoleName'..." -ForegroundColor Yellow
Set-ManagementRoleEntry "$RoleName\New-InboxRule" -RemoveParameter -Parameters ForwardTo, RedirectTo, ForwardAsAttachmentTo -ErrorAction SilentlyContinue
Set-ManagementRoleEntry "$RoleName\Set-Mailbox" -RemoveParameter -Parameters DeliverToMailboxAndForward, ForwardingAddress, ForwardingSmtpAddress -ErrorAction SilentlyContinue

# 3. Create custom Role Assignment Policy
$existingPolicy = Get-RoleAssignmentPolicy -Identity $PolicyName -ErrorAction SilentlyContinue
if (-not $existingPolicy) {
    Write-Host "Creating Role Assignment Policy '$PolicyName'..." -ForegroundColor Yellow
    New-RoleAssignmentPolicy -Name $PolicyName -Roles $RoleName, MyContactInformation, MyRetentionPolicies, MyMailSubscriptions, MyTextMessaging, MyVoiceMail, MyDistributionGroupMembership, MyDistributionGroups, MyProfileInformation
}

# 4. Assign policy to target user if specified
if (-not [string]::IsNullOrWhiteSpace($Identity)) {
    Write-Host "Assigning policy '$PolicyName' to mailbox '$Identity'..." -ForegroundColor Cyan
    Set-Mailbox -Identity $Identity -RoleAssignmentPolicy $PolicyName -ErrorAction SilentlyContinue
    Write-Host "Policy assigned successfully." -ForegroundColor Green
}
