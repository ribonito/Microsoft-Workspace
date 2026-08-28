<#
.SYNOPSIS
    EXO-022 | RBAC Management.

.DESCRIPTION
    Manage Exchange Online role-based access control.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-022 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20RBAC.ps1

.NOTES
    Name: EXO-022_RBAC-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# #>
$role = "CustomMyBaseOptions";
New-ManagementRole -Name $role -Parent MyBaseOptions

Set-ManagementRoleEntry $role\New-InboxRule -RemoveParameter -Parameters ForwardTo, RedirectTo, ForwardAsAttachmentTo
Set-ManagementRoleEntry $role\Set-Mailbox -RemoveParameter -Parameters DeliverToMailboxAndForward,ForwardingAddress,ForwardingSmtpAddress

$policy = "CustomMyBaseOptionsPolicy";
New-RoleAssignmentPolicy -Name $policy -Roles $role,MyContactInformation,MyRetentionPolicies,MyMailSubscriptions,MyTextMessaging,MyVoiceMail,MyDistributionGroupMembership,MyDistributionGroups,MyProfileInformation
Set-Mailbox -Identity "user@domain.com" -RoleAssignmentPolicy $policy
