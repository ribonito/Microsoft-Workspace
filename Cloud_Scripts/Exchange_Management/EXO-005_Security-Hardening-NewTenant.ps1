<#
.SYNOPSIS
    EXO-005 | Exchange Online - Security Hardening for New Tenant Onboarding.

.DESCRIPTION
    Consolidated security hardening script for Exchange Online, designed to be
    run as part of a new Microsoft 365 tenant onboarding. Covers:

        1. Block external auto-forwarding (Transport Rule)
        2. Enable email encryption rule (keyword-based "Secure")
        3. Restrict anonymous calendar sharing to Free/Busy only
        4. Configure outbound spam notifications
        5. Set up Microsoft Defender ATP: Safe Attachments + Safe Links
        6. Configure Anti-Phishing policy (impersonation protection, mailbox intelligence)

    Run interactively during onboarding — the script will prompt for required
    tenant-specific values.

.PRODUCT
    Exchange Online / Microsoft Defender for Office 365

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    .\EXO-005_Security-Hardening-NewTenant.ps1

.NOTES
    - Module: ExchangeOnlineManagement
    - Run with "Global Administrator" or "Security Administrator" role
    - Review and adjust policy names before running in production
#>

#region ── Connection ─────────────────────────────────────────────────────────
Connect-ExchangeOnline
#endregion

#region ── 1. Block External Auto-Forwarding ──────────────────────────────────
$externalTransportRuleName = "Block Auto-Forwarding"
$rejectMessageText = "To improve security, auto-forwarding rules to external email addresses have been disabled. Please contact your helpdesk if you want to create an exception."

$externalForwardRule = Get-TransportRule | Where-Object { $_.Identity -contains $externalTransportRuleName }

if (-not $externalForwardRule) {
    Write-Output "Auto-forwarding rule not found — creating rule."
    New-TransportRule `
        -Name                          "Block Auto-forwarding" `
        -Priority                      1 `
        -SentToScope                   NotInOrganization `
        -FromScope                     InOrganization `
        -MessageTypeMatches            AutoForward `
        -RejectMessageEnhancedStatusCode "5.7.1" `
        -RejectMessageReasonText       $rejectMessageText
}
#endregion

#region ── 2. Email Encryption Rule (keyword "Secure" in subject) ─────────────
New-TransportRule -Name "Encrypt Email" `
    -SubjectContainsWords "Secure" `
    -ApplyRightsProtectionTemplate "Encrypt"
#endregion

#region ── 3. Calendar Sharing - Restrict to Free/Busy (Anonymous) ────────────
Set-SharingPolicy -Identity "Default Sharing Policy" `
    -Domains "Anonymous: CalendarSharingFreeBusySimple"
#endregion

#region ── 4. Outbound Spam Notifications ────────────────────────────────────
$NotificationEmail = Read-Host -Prompt "Enter the email address for outbound spam notifications"
Set-HostedOutboundSpamFilterPolicy Default `
    -NotifyOutboundSpam           $true `
    -NotifyOutboundSpamRecipients $NotificationEmail
#endregion

#region ── 5. ATP Safe Attachments + Safe Links ───────────────────────────────
$DomainName   = Read-Host -Prompt "Enter the Tenant Domain Name (e.g. contoso.com)"
$WhiteListUrl = Read-Host -Prompt "Enter URLs to whitelist (comma-separated). Press Enter if none"

New-SafeAttachmentPolicy -Name "Policy 1" -Action DynamicDelivery -Enable $true -ActionOnError $true
New-SafeAttachmentRule   -Name "Safe Attachment Policy" -SafeAttachmentPolicy "Policy 1" -RecipientDomainIs $DomainName

New-SafeLinksPolicy -Name "Policy 1" `
    -DoNotTrackUserClicks $true `
    -EnableForInternalSenders $true `
    -DoNotAllowClickThrough $true `
    -TrackClicks $false `
    -ScanUrls $true `
    -AllowClickThrough $false `
    -DoNotRewriteUrls $WhiteListUrl `
    -IsEnabled $true

New-SafeLinksRule -Name "SafeLinksPolicy" `
    -SafeLinksPolicy "Policy 1" `
    -RecipientDomainIs $DomainName `
    -Enabled $true
#endregion

#region ── 6. Anti-Phishing Policy ──────────────────────────────────────────
# Format: "DisplayName;email@domain.com" (comma-separated for multiple)
$ProtectedUsers    = Read-Host -Prompt "Enter users to protect from impersonation (e.g. John CEO;john@contoso.com)"
$ExcludedDomains   = Read-Host -Prompt "Domains to exclude/whitelist (comma-separated), or type 'null'"
$ExcludedSenders   = Read-Host -Prompt "Senders to exclude/whitelist (comma-separated), or type 'null@null.com'"

Set-AntiPhishPolicy -Identity "Office365 AntiPhish Default" `
    -EnableOrganizationDomainsProtection     $true `
    -TargetedDomainProtectionAction          Quarantine `
    -EnableTargetedUserProtection            $true `
    -TargetedUsersToProtect                  $ProtectedUsers `
    -TargetedUserProtectionAction            Quarantine `
    -EnableMailboxIntelligence               $true `
    -EnableMailboxIntelligenceProtection     $true `
    -MailboxIntelligenceProtectionAction     Quarantine `
    -EnableSimilarUsersSafetyTips            $true `
    -EnableSimilarDomainsSafetyTips          $true `
    -EnableUnusualCharactersSafetyTips       $true `
    -ExcludedDomains                         $ExcludedDomains `
    -ExcludedSenders                         $ExcludedSenders
#endregion
