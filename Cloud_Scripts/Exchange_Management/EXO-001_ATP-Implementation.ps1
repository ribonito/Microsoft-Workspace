<#
.SYNOPSIS
    EXO-001 | Exchange Online - Enable Microsoft Defender for Office 365 (ATP)
    Safe Attachments and Safe Links policies setup.

.DESCRIPTION
    This script sets up Microsoft Defender for Office 365 (formerly ATP) by:
        - Installing and updating required PowerShell modules
        - Connecting to Exchange Online
        - Creating a Safe Attachments policy with Dynamic Delivery
        - Creating a Safe Links policy with click-through protection disabled
        - Binding both policies to the specified tenant domain

    NOTE: Requires the ExchangeOnlineManagement module and an admin account
    with at least the "Security Administrator" role in Microsoft 365.

.PRODUCT
    Exchange Online / Microsoft Defender for Office 365

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    .\EXO-001_ATP-Implementation.ps1
    (You will be prompted for the tenant domain and any URLs to whitelist)

.NOTES
    - Module: ExchangeOnlineManagement
    - Run with global/security admin credentials
#>

#region ── Module Setup ───────────────────────────────────────────────────────
Install-Module PowershellGet -Force
Update-Module PowershellGet
Set-ExecutionPolicy RemoteSigned
Install-Module -Name ExchangeOnlineManagement
#endregion

#region ── Connection ─────────────────────────────────────────────────────────
Connect-ExchangeOnline
#endregion

#region ── Domain Configuration ──────────────────────────────────────────────
$DomainName  = Read-Host -Prompt "Enter the Tenant Domain Name (e.g. contoso.com)"
$WhiteListUrl = Read-Host -Prompt "Enter any URLs to whitelist (comma-separated). Press Enter if none"
#endregion

#region ── Safe Attachments Policy ───────────────────────────────────────────
New-SafeAttachmentPolicy -Name "Policy 1" -Action DynamicDelivery -Enable $true -ActionOnError $true
New-SafeAttachmentRule   -Name "Safe Attachment Policy" -SafeAttachmentPolicy "Policy 1" -RecipientDomainIs $DomainName
#endregion

#region ── Safe Links Policy ─────────────────────────────────────────────────
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
