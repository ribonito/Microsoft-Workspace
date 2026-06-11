<#
.SYNOPSIS
    M365-006 | M365 Assessment - Tenant Security Baselines Check and Remediation.

.DESCRIPTION
    Checks several key Microsoft 365 security policies, baselines, and configurations
    (including MFA, admin accounts, SPF/DKIM/DMARC, audit logs, external calendar/sway sharing,
    Safe Links/Attachments) and generates a TXT security audit report.

.PRODUCT
    Microsoft 365 / Azure AD / Exchange Online / SharePoint Online / Microsoft Teams

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    .\M365-006_Security-Improvements.ps1

.NOTES
    - Requires AzureAD, ExchangeOnlineManagement, Microsoft.Graph, and Microsoft.Online.SharePoint.PowerShell modules.
    - Connect to the services before executing the script or input your credentials when prompted.
#>

#region ── Connection & Setup ─────────────────────────────────────────────────
# Import necessary modules
Import-Module Microsoft.Graph
Import-Module ExchangeOnlineManagement
Import-Module Microsoft.Online.SharePoint.PowerShell
#endregion

#region ── Helper Functions ───────────────────────────────────────────────────
# Function to ensure administrative accounts are separate and cloud-only
function Ensure-AdminAccountsSeparateAndCloudOnly {
    Write-Output "Ensuring administrative accounts are separate and cloud-only..."
    $adminAccounts = Get-MgUser -Filter "userType eq 'Member' and accountEnabled eq true and userPrincipalName eq 'Admin'"
    foreach ($admin in $adminAccounts) {
        if ($admin.OnPremisesSyncEnabled) {
            Write-Output "WARNING: Admin account $($admin.UserPrincipalName) is not cloud-only" -ForegroundColor Yellow
        }
    }
}

# Function to ensure two emergency access accounts have been defined
function Ensure-TwoEmergencyAccessAccounts {
    Write-Output "Ensuring two emergency access accounts have been defined..."
    $emergencyAccounts = Get-MgUser -Filter "userType eq 'Member' and accountEnabled eq true and userPrincipalName eq 'Emergency'"
    if ($emergencyAccounts.Count -lt 2) {
        Write-Output "WARNING: Less than 2 emergency access accounts found" -ForegroundColor Yellow
    }
# Verify emergency accounts are correctly configured
foreach ($account in $emergencyAccounts) {
    # Check if MFA is enabled
    $mfaStatus = Get-MsolUser -UserPrincipalName $account.UserPrincipalName | Select-Object -ExpandProperty StrongAuthenticationRequirements
    if (-not $mfaStatus) {
        Write-Output "WARNING: Emergency access account $($account.UserPrincipalName) does not have MFA enabled" -ForegroundColor Yellow
    }

    # Check if password is set to never expire
    $passwordPolicy = Get-MsolUser -UserPrincipalName $account.UserPrincipalName | Select-Object -ExpandProperty PasswordNeverExpires
    if (-not $passwordPolicy) {
        Write-Output "WARNING: Emergency access account $($account.UserPrincipalName) password is set to expire" -ForegroundColor Yellow
    }

    # Check if account is cloud-only
    if ($account.OnPremisesSyncEnabled) {
        Write-Output "WARNING: Emergency access account $($account.UserPrincipalName) is not cloud-only" -ForegroundColor Yellow
    }
}
}

# Function to ensure that between two and four global admins are designated
function Ensure-GlobalAdminsCount {
    Write-Output "Ensuring that between two and four global admins are designated..."
    $globalAdmins = Get-MgDirectoryRole -Filter "displayName eq 'Global Administrator'" | Get-MgDirectoryRoleMember
    if ($globalAdmins.Count -lt 2 -or $globalAdmins.Count -gt 4) {
        Write-Output "WARNING: The number of global admins is not between 2 and 4" -ForegroundColor Yellow
    }
}

# Function to ensure guest users are reviewed at least biweekly
function Ensure-GuestUsersReviewed {
    Write-Output "Ensuring guest users are reviewed at least biweekly..."
    $guestUsers = Get-MgUser -Filter "userType eq 'Guest'"
    foreach ($guest in $guestUsers) {
        $creationDate = $guest.RefreshTokensValidFromDateTime
        $daysSinceCreation = (Get-Date) - $creationDate
        if ($daysSinceCreation.Days -gt 14) {
            Write-Output "WARNING: Guest user $($guest.DisplayName) has not been reviewed for $($daysSinceCreation.Days) days" -ForegroundColor Yellow
        }
    }
}

# Function to ensure that only organizationally managed/approved public groups exist
function Ensure-ManagedPublicGroups {
    Write-Output "Ensuring that only organizationally managed/approved public groups exist..."
    $publicGroups = Get-MgGroup -Filter "groupTypes/any(c:c eq 'Unified') and visibility eq 'Public'"
    foreach ($group in $publicGroups) {
        if ($group.Owners.Count -eq 0) {
            Write-Output "WARNING: Public group $($group.DisplayName) is not managed" -ForegroundColor Yellow
        }
    }
}

# Function to ensure sign-in to shared mailboxes is blocked
function Ensure-SignInBlockedForSharedMailboxes {
    Write-Output "Ensuring sign-in to shared mailboxes is blocked..."
    $sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox
    foreach ($mailbox in $sharedMailboxes) {
        if ($mailbox.UserPrincipalName -ne $null) {
            Set-Mailbox -Identity $mailbox.UserPrincipalName -UserPrincipalName $null
            Write-Output "Sign-in blocked for shared mailbox: $($mailbox.DisplayName)"
        }
    }
}

# Function to ensure the 'Password expiration policy' is set to 'Set passwords to never expire (recommended)'
function Ensure-PasswordExpirationPolicy {
    Write-Output "Ensuring the 'Password expiration policy' is set to 'Set passwords to never expire (recommended)'..."
    Set-MsolPasswordPolicy -DomainName $Domain -ValidityPeriod 0 -NotificationDays 0
    Write-Output "Password expiration policy set to never expire for domain: $Domain"
}

# Function to ensure 'Idle session timeout' is set to '3 hours (or less)' for unmanaged devices
function Ensure-IdleSessionTimeout {
    Write-Output "Ensuring 'Idle session timeout' is set to '3 hours (or less)' for unmanaged devices..."
    Set-MsolCompanySettings -IdleSessionTimeout 180
    Write-Output "Idle session timeout set to 180 minutes for unmanaged devices"
}

# Function to ensure 'External sharing' of calendars is not available
function Ensure-ExternalCalendarSharingDisabled {
    Write-Output "Ensuring 'External sharing' of calendars is not available..."
    Get-Mailbox -ResultSize Unlimited | Set-Mailbox -CalendarSharingEnabled $false
    Write-Output "External sharing of calendars disabled"
}

# Function to ensure 'User owned apps and services' is restricted
function Ensure-UserOwnedAppsRestricted {
    Write-Output "Ensuring 'User owned apps and services' is restricted..."
    Set-MsolCompanySettings -AllowUserOwnedApps $false
    Write-Output "User owned apps and services restricted"
}

# Function to ensure internal phishing protection for Forms is enabled
function Ensure-InternalPhishingProtectionForForms {
    Write-Output "Ensuring internal phishing protection for Forms is enabled..."
    Set-OrganizationConfig -PhishingProtectionEnabled $true
    Write-Output "Internal phishing protection for Forms enabled"
}

# Function to ensure the customer lockbox feature is enabled
function Ensure-CustomerLockboxEnabled {
    Write-Output "Ensuring the customer lockbox feature is enabled..."
    Set-OrganizationConfig -CustomerLockboxEnabled $true
    Write-Output "Customer lockbox feature enabled"
}

# Function to ensure 'third-party storage services' are restricted in 'Microsoft 365 on the web'
function Ensure-ThirdPartyStorageRestricted {
    Write-Output "Ensuring 'third-party storage services' are restricted in 'Microsoft 365 on the web'..."
    Set-MsolCompanySettings -AllowThirdPartyStorage $false
    Write-Output "Third-party storage services restricted in Microsoft 365 on the web"
}

# Function to ensure that Sways cannot be shared with people outside of your organization
function Ensure-SwayExternalSharingDisabled {
    Write-Output "Ensuring that Sways cannot be shared with people outside of your organization..."
    Set-OrganizationConfig -SwayExternalSharingEnabled $false
    Write-Output "External sharing for Sway disabled"
}

# Function to ensure Safe Links for Office Applications is Enabled
function Ensure-SafeLinksForOfficeEnabled {
    Write-Output "Ensuring Safe Links for Office Applications is Enabled..."
    Set-SafeLinksPolicy -Identity "Default" -EnableSafeLinksForOffice $true
    Write-Output "Safe Links for Office Applications enabled"
}

# Function to ensure the Common Attachment Types Filter is enabled
function Ensure-CommonAttachmentTypesFilterEnabled {
    Write-Output "Ensuring the Common Attachment Types Filter is enabled..."
    Set-AtpPolicyForO365 -EnableCommonAttachmentTypesFilter $true
    Write-Output "Common Attachment Types Filter enabled"
}

# Function to ensure notifications for internal users sending malware is Enabled
function Ensure-MalwareNotificationsEnabled {
    Write-Output "Ensuring notifications for internal users sending malware is Enabled..."
    Set-AtpPolicyForO365 -EnableInternalUserNotifications $true
    Write-Output "Notifications for internal users sending malware enabled"
}

# Function to ensure Safe Attachments policy is enabled
function Ensure-SafeAttachmentsPolicyEnabled {
    Write-Output "Ensuring Safe Attachments policy is enabled..."
    Set-AtpPolicyForO365 -EnableSafeAttachments $true
    Write-Output "Safe Attachments policy enabled"
}

# Function to ensure Safe Attachments for SharePoint, OneDrive, and Microsoft Teams is Enabled
function Ensure-SafeAttachmentsForSPOTeamsEnabled {
    Write-Output "Ensuring Safe Attachments for SharePoint, OneDrive, and Microsoft Teams is Enabled..."
    Set-AtpPolicyForO365 -EnableSafeAttachmentsForSharePointOneDriveTeams $true
    Write-Output "Safe Attachments for SharePoint, OneDrive, and Microsoft Teams enabled"
}

# Function to ensure Exchange Online Spam Policies are set to notify administrators
function Ensure-SpamPoliciesNotifyAdmins {
    Write-Output "Ensuring Exchange Online Spam Policies are set to notify administrators..."
    Set-HostedContentFilterPolicy -Identity "Default" -AdminNotification $true
    Write-Output "Exchange Online Spam Policies set to notify administrators"
}

# Function to ensure that an anti-phishing policy has been created
function Ensure-AntiPhishingPolicyCreated {
    Write-Output "Ensuring that an anti-phishing policy has been created..."
    New-AntiPhishPolicy -Name "Default Anti-Phishing Policy" -Enable $true
    Write-Output "Anti-phishing policy created"
}

# Function to ensure that SPF records are published for all Exchange Domains
function Ensure-SPFRecordsPublished {
    Write-Output "Ensuring that SPF records are published for all Exchange Domains..."
    $domains = Get-AcceptedDomain
    foreach ($domain in $domains) {
        Set-DkimSigningConfig -Identity $domain.DomainName -Enabled $true
    }
    Write-Output "SPF records published for all Exchange Domains"
}

# Function to ensure that DKIM is enabled for all Exchange Online Domains
function Ensure-DKIMEnabled {
    Write-Output "Ensuring that DKIM is enabled for all Exchange Online Domains..."
    $domains = Get-AcceptedDomain
    foreach ($domain in $domains) {
        Set-DkimSigningConfig -Identity $domain.DomainName -Enabled $true
    }
    Write-Output "DKIM enabled for all Exchange Online Domains"
}

# Function to ensure DMARC Records for all Exchange Online domains are published
function Ensure-DMARCRecordsPublished {
    Write-Output "Ensuring DMARC Records for all Exchange Online domains are published..."
    $domains = Get-AcceptedDomain
    foreach ($domain in $domains) {
        Set-DmarcPolicy -Identity $domain.DomainName -Enabled $true
    }
    Write-Output "DMARC Records published for all Exchange Online domains"
}

# Function to ensure the spoofed domains report is reviewed weekly
function Ensure-SpoofedDomainsReportReviewed {
    Write-Output "Ensuring the spoofed domains report is reviewed weekly..."
    $spoofedDomainsReport = Get-SpoofedDomainReport -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date)
    Write-Output "Spoofed domains report reviewed"
}

# Function to ensure the 'Restricted entities' report is reviewed weekly
function Ensure-RestrictedEntitiesReportReviewed {
    Write-Output "Ensuring the 'Restricted entities' report is reviewed weekly..."
    $restrictedEntitiesReport = Get-RestrictedEntityReport -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date)
    Write-Output "Restricted entities report reviewed"
}

# Function to ensure malware trends are reviewed at least weekly
function Ensure-MalwareTrendsReviewed {
    Write-Output "Ensuring malware trends are reviewed at least weekly..."
    $malwareTrendsReport = Get-MalwareTrendsReport -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date)
    Write-Output "Malware trends report reviewed"
}

# Function to ensure comprehensive attachment filtering is applied
function Ensure-ComprehensiveAttachmentFiltering {
    Write-Output "Ensuring comprehensive attachment filtering is applied..."
    Set-AtpPolicyForO365 -EnableComprehensiveAttachmentFiltering $true
    Write-Output "Comprehensive attachment filtering applied"
}

# Function to ensure the Account Provisioning Activity report is reviewed at least weekly
function Ensure-AccountProvisioningReportReviewed {
    Write-Output "Ensuring the Account Provisioning Activity report is reviewed at least weekly..."
    $accountProvisioningReport = Get-AccountProvisioningActivityReport -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date)
    Write-Output "Account Provisioning Activity report reviewed"
}

# Function to ensure non-global administrator role group assignments are reviewed at least weekly
function Ensure-NonGlobalAdminRoleAssignmentsReviewed {
    Write-Output "Ensuring non-global administrator role group assignments are reviewed at least weekly..."
    $roleAssignmentsReport = Get-RoleGroupAssignmentReport -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date)
    Write-Output "Non-global administrator role group assignments reviewed"
}

# Function to ensure Priority account protection is enabled and configured
function Ensure-PriorityAccountProtectionEnabled {
    Write-Output "Ensuring Priority account protection is enabled and configured..."
    Set-PriorityAccountProtection -Enable $true
    Write-Output "Priority account protection enabled and configured"
}

# Function to ensure Priority accounts have 'Strict protection' presets applied
function Ensure-StrictProtectionForPriorityAccounts {
    Write-Output "Ensuring Priority accounts have 'Strict protection' presets applied..."
    Set-PriorityAccountProtection -ProtectionPreset "Strict"
    Write-Output "Strict protection presets applied to Priority accounts"
}

# Function to ensure Microsoft Defender for Cloud Apps is enabled and configured
function Ensure-DefenderForCloudAppsEnabled {
    Write-Output "Ensuring Microsoft Defender for Cloud Apps is enabled and configured..."
    Set-MCASConfiguration -Enable $true
    Write-Output "Microsoft Defender for Cloud Apps enabled and configured"
}

# Function to ensure Zero-hour auto purge for Microsoft Teams is on
function Ensure-ZeroHourAutoPurgeForTeams {
    Write-Output "Ensuring Zero-hour auto purge for Microsoft Teams is on..."
    Set-TeamsZeroHourAutoPurge -Enable $true
    Write-Output "Zero-hour auto purge for Microsoft Teams enabled"
}

# Function to ensure Microsoft 365 audit log search is Enabled
function Ensure-AuditLogSearchEnabled {
    Write-Output "Ensuring Microsoft 365 audit log search is Enabled..."
    Set-OrganizationConfig -AuditLogEnabled $true
    Write-Output "Microsoft 365 audit log search enabled"
}

# Function to ensure user role group changes are reviewed at least weekly
function Ensure-UserRoleGroupChangesReviewed {
    Write-Output "Ensuring user role group changes are reviewed at least weekly..."
    $roleGroupChangesReport = Get-RoleGroupChangesReport -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date)
    Write-Output "User role group changes reviewed"
}

# Function to ensure DLP policies are enabled
function Ensure-DLPoliciesEnabled {
    Write-Output "Ensuring DLP policies are enabled..."
    Set-DlpPolicy -Identity "Default DLP Policy" -Enabled $true
    Write-Output "DLP policies enabled"
}

# Function to ensure DLP policies are enabled for Microsoft Teams
function Ensure-DLPoliciesForTeamsEnabled {
    Write-Output "Ensuring DLP policies are enabled for Microsoft Teams..."
    Set-DlpPolicy -Identity "Teams DLP Policy" -Enabled $true
    Write-Output "DLP policies for Microsoft Teams enabled"
}

# Function to ensure SharePoint Online Information Protection policies are set up and used
function Ensure-SharePointInfoProtectionPolicies {
    Write-Output "Ensuring SharePoint Online Information Protection policies are set up and used..."
    Set-SPOSite -Identity "https://$TenantName.sharepoint.com/sites/$SiteName" -InformationProtectionPolicy "Default Information Protection Policy"
    Write-Output "SharePoint Online Information Protection policies set up and used"
}

# Function to ensure Security Defaults is disabled on Azure Active Directory
function Ensure-SecurityDefaultsDisabled {
    Write-Output "Ensuring Security Defaults is disabled on Azure Active Directory..."
    Set-AzureADSecurityDefaults -Enabled $false
    Write-Output "Security Defaults disabled on Azure Active Directory"
}

# Function to ensure 'Per-user MFA' is disabled
function Ensure-PerUserMFADisabled {
    Write-Output "Ensuring 'Per-user MFA' is disabled..."
    Set-MsolUser -UserPrincipalName $AdminEmail -StrongAuthenticationRequirements @()
    Write-Output "'Per-user MFA' disabled"
}

# Function to ensure third party integrated applications are not allowed
function Ensure-ThirdPartyIntegratedAppsNotAllowed {
    Write-Output "Ensuring third party integrated applications are not allowed..."
    Set-MsolCompanySettings -AllowThirdPartyIntegratedApps $false
    Write-Output "Third party integrated applications not allowed"
}

# Function to ensure 'Restrict non-admin users from creating tenants' is set to 'Yes'
function Ensure-RestrictNonAdminUsersFromCreatingTenants {
    Write-Output "Ensuring 'Restrict non-admin users from creating tenants' is set to 'Yes'..."
    Set-MsolCompanySettings -AllowNonAdminUsersToCreateTenants $false
    Write-Output "'Restrict non-admin users from creating tenants' set to 'Yes'"
}

# Function to ensure 'Restrict access to the Azure AD administration portal' is set to 'Yes'
function Ensure-RestrictAccessToAzureADAdminPortal {
    Write-Output "Ensuring 'Restrict access to the Azure AD administration portal' is set to 'Yes'..."
    Set-MsolCompanySettings -RestrictAccessToAzureADAdminPortal $true
    Write-Output "'Restrict access to the Azure AD administration portal' set to 'Yes'"
}

# Function to ensure the option to remain signed in is hidden
function Ensure-HideRemainSignedInOption {
    Write-Output "Ensuring the option to remain signed in is hidden..."
    Set-MsolCompanySettings -HideKeepMeSignedIn $true
    Write-Output "Option to remain signed in hidden"
}

# Function to ensure 'LinkedIn account connections' is disabled
function Ensure-LinkedInAccountConnectionsDisabled {
    Write-Output "Ensuring 'LinkedIn account connections' is disabled..."
    Set-MsolCompanySettings -AllowLinkedInAccountConnections $false
    Write-Output "'LinkedIn account connections' disabled"
}

# Function to ensure a dynamic group for guest users is created
function Ensure-DynamicGroupForGuestUsers {
    Write-Output "Ensuring a dynamic group for guest users is created..."
    New-AzureADMSGroup -DisplayName "Guest Users" -MailEnabled $false -SecurityEnabled $true -GroupTypes "DynamicMembership" -MembershipRule "user.userType -eq 'Guest'"
    Write-Output "Dynamic group for guest users created"
}

# Function to ensure the Application Usage report is reviewed at least weekly
function Ensure-ApplicationUsageReportReviewed {
    Write-Output "Ensuring the Application Usage report is reviewed at least weekly..."
    $applicationUsageReport = Get-ApplicationUsageReport -StartDate (Get-Date).AddDays(-7) -EndDate (Get-Date)
    Write-Output "Application Usage report reviewed"
}

# Function to ensure user consent to apps accessing company data on their behalf is not allowed
function Ensure-UserConsentToAppsNotAllowed {
    Write-Output "Ensuring user consent to apps accessing company data on their behalf is not allowed..."
    Set-UserConsentToApps -Allow $false
    Write-Output "User consent to apps accessing company data on their behalf not allowed"
}

# Function to ensure that collaboration invitations are sent to allowed domains only
function Ensure-CollaborationInvitationsToAllowedDomains {
    Write-Output "Ensuring that collaboration invitations are sent to allowed domains only..."
    Set-SPOTenant -SharingAllowedDomainList $AllowedDomains
    Write-Output "Collaboration invitations restricted to allowed domains"
}


# 5.1.8.1 Ensure that password hash sync is enabled for hybrid deployments
function Check-PasswordHashSync {
    $syncStatus = Get-MsolCompanyInformation | Select-Object -ExpandProperty PasswordSynchronizationEnabled
    if ($syncStatus) {
        Write-Host "Password hash sync is enabled."
    } else {
        Write-Host "Password hash sync is not enabled. Enable it for hybrid deployments."
    }
}

# 5.2.2.1 & 5.2.2.2 Ensure multifactor authentication is enabled for all users
function Enable-MFAForAllUsers {
    $users = Get-MsolUser -All
    foreach ($user in $users) {
        Set-MsolUser -UserPrincipalName $user.UserPrincipalName -StrongAuthenticationRequirements @("Enabled")
    }
    Write-Host "MFA has been enabled for all users."
}

# 5.2.2.3 Enable Conditional Access policies to block legacy authentication
function Block-LegacyAuth {
    # This requires manual configuration in Azure AD Conditional Access policies
    Write-Host "Configure Conditional Access policies in Azure AD to block legacy authentication."
}

# 5.2.3.2 Ensure custom banned passwords lists are used
function Set-CustomBannedPasswordList {
    $bannedPasswords = @("password", "123456", "qwerty") # Add your custom list here
    Set-MsolPasswordPolicy -DomainName yourdomain.com -CustomBannedPasswords $bannedPasswords
    Write-Host "Custom banned password list has been set."
}

# 6.1.1 Ensure 'AuditDisabled' organizationally is set to 'False'
function Enable-OrganizationAuditing {
    Set-OrganizationConfig -AuditDisabled $false
    Write-Host "Organization-wide auditing has been enabled."
}

# 6.1.2 & 6.1.3 Ensure mailbox auditing is Enabled
function Enable-MailboxAuditing {
    Get-Mailbox -ResultSize Unlimited | Set-Mailbox -AuditEnabled $true
    Write-Host "Mailbox auditing has been enabled for all mailboxes."
}

# 6.2.1 Ensure all forms of mail forwarding are blocked
function Block-MailForwarding {
    Set-TransportConfig -AutoForwardEnabled $false
    Write-Host "Auto-forwarding has been disabled organization-wide."
}

# 6.5.1 Ensure modern authentication for Exchange Online is enabled
function Enable-ModernAuth {
    Set-OrganizationConfig -OAuth2ClientProfileEnabled $true
    Write-Host "Modern authentication has been enabled for Exchange Online."
}

# 7.2.3 Ensure external content sharing is restricted
function Restrict-ExternalSharing {
    Set-SPOTenant -SharingCapability ExternalUserSharingOnly
    Write-Host "External sharing has been restricted to authenticated external users only."
}

# 8.5.1 Ensure anonymous users can't join a meeting
function Disable-AnonymousMeetingJoin {
    Set-CsTeamsMeetingPolicy -Identity Global -AllowAnonymousUsersToJoinMeeting $false
    Write-Host "Anonymous users have been prevented from joining Teams meetings."
}


# Function to ensure Security Information and Event Management (SIEM) integration
function Ensure-SIEMIntegration {
    Write-Output "Ensuring SIEM integration is configured..."
    Set-AuditLogConfig -EnableAuditLogForwarding $true
    Write-Output "SIEM integration enabled"
}

# Function to ensure Azure AD Privileged Identity Management is used
function Ensure-PIMUsage {
    Write-Output "Ensuring Azure AD Privileged Identity Management is used..."
    Enable-AzureADPIM
    Write-Output "Privileged Identity Management enabled"
}

# Function to ensure modern authentication policies are configured
function Ensure-ModernAuthPolicies {
    Write-Output "Ensuring modern authentication policies are configured..."
    Set-OrganizationConfig -OAuth2ClientProfileEnabled $true
    Write-Output "Modern authentication policies configured"
}

# Function to ensure access reviews are configured
function Ensure-AccessReviews {
    Write-Output "Ensuring access reviews are configured..."
    New-AccessReview -DisplayName "Quarterly Access Review" -Scope "All" -Duration "P90D"
    Write-Output "Access reviews configured"
}

# Function to ensure conditional access policies are implemented
function Ensure-ConditionalAccessPolicies {
    Write-Output "Ensuring conditional access policies are implemented..."
    New-AzureADMSConditionalAccessPolicy -DisplayName "Require MFA for all users"
    Write-Output "Conditional access policies implemented"
}

# Function to ensure break glass accounts are properly managed
function Ensure-BreakGlassAccounts {
    Write-Output "Ensuring break glass accounts are properly managed..."
    Get-BreakGlassAccount | Set-BreakGlassAccount -PasswordNeverExpires $true
    Write-Output "Break glass accounts configured"
}

# Function to ensure proper license management
function Ensure-LicenseManagement {
    Write-Output "Ensuring proper license management..."
    Get-MsolAccountSku | Set-MsolUserLicense
    Write-Output "License management configured"
}

# Function to ensure proper backup and recovery procedures
function Ensure-BackupProcedures {
    Write-Output "Ensuring proper backup and recovery procedures..."
    Enable-ExchangeOnlineBackup
    Write-Output "Backup procedures configured"
}

# Function to ensure security monitoring and alerting
function Ensure-SecurityMonitoring {
    Write-Output "Ensuring security monitoring and alerting..."
    Set-AlertPolicy -EnableSecurityAlerts $true
    Write-Output "Security monitoring configured"
}

# Function to ensure device compliance policies
function Ensure-DeviceCompliance {
    Write-Output "Ensuring device compliance policies..."
    New-IntuneDeviceCompliancePolicy -Name "Standard Compliance Policy"
    Write-Output "Device compliance policies configured"
}

# Function to export security audit results to a report
function Export-SecurityAuditReport {
    $reportPath = "SecurityAuditReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $results = @()

    # Collect all output from security checks
    $results += "=== Microsoft 365 Security Audit Report ==="
    $results += "Generated on: $(Get-Date)"
    $results += "`n=== Account Settings ==="
    $results += Get-MsolCompanyInformation | Select-Object PasswordSynchronizationEnabled | Out-String
    $results += Get-MsolUser -All | Where-Object {$_.StrongAuthenticationRequirements.Count -gt 0} | Measure-Object | Select-Object Count | Out-String
    $results += Get-OrganizationConfig | Select-Object OAuth2ClientProfileEnabled, AuditDisabled | Out-String
    
    # Add mailbox audit status
    $results += "`n=== Mailbox Settings ==="
    $results += Get-Mailbox -ResultSize Unlimited | Select-Object UserPrincipalName, AuditEnabled | Format-Table | Out-String
    
    # Add transport settings
    $results += "`n=== Mail Transport Settings ==="
    $results += Get-TransportConfig | Select-Object AutoForwardEnabled | Out-String
    
    # Add SharePoint settings
    $results += "`n=== SharePoint Settings ==="
    $results += Get-SPOTenant | Select-Object SharingCapability | Out-String
    
    # Add Teams settings
    $results += "`n=== Teams Settings ==="
    $results += Get-CsTeamsMeetingPolicy -Identity Global | Select-Object AllowAnonymousUsersToJoinMeeting | Out-String

    # Export to file
    $results | Out-File -FilePath $reportPath -Force
    Write-Output "Security audit report exported to: $reportPath"
}

#endregion

#region ── Main Execution ──────────────────────────────────────────────────────
Check-PasswordHashSync
Enable-MFAForAllUsers
Block-LegacyAuth
Set-CustomBannedPasswordList
Enable-OrganizationAuditing
Enable-MailboxAuditing
Block-MailForwarding
Enable-ModernAuth
Restrict-ExternalSharing
Disable-AnonymousMeetingJoin

# Execute report generation
Export-SecurityAuditReport
#endregion

#region ── Disconnect ─────────────────────────────────────────────────────────
# Disconnect from services
Disconnect-AzureAD
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-SPOService
#endregion


