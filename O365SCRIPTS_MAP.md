# O365scripts Integration Map

> Source: [O365scripts/O365scripts](https://github.com/O365scripts/O365scripts)
> License: See upstream repository. Integrated scripts retain original logic with standardized naming.

## Newly Integrated Scripts

| Workspace ID | Workspace Path | Upstream Original | Description |
|--------------|----------------|-------------------|-------------|
| EXO-008 | `Cloud_Scripts/Exchange_Management/EXO-008_Distribution-Group-Management.ps1` | `Exchange Online/EXO - Distribution Group Management.ps1` | Full distribution group membership overview and CSV export. |
| EXO-009 | `Cloud_Scripts/Exchange_Management/EXO-009_Distribution-Group-Member-Management.ps1` | `Exchange Online/EXO - Distribution Group Member Management.ps1` | Add, remove, and manage distribution group members. |
| EXO-010 | `Cloud_Scripts/Exchange_Management/EXO-010_Distribution-Groups.ps1` | `Exchange Online/EXO - Distribution Groups.ps1` | Create, modify, and remove distribution groups. |
| EXO-011 | `Cloud_Scripts/Exchange_Management/EXO-011_Mailbox-Alias-Management.ps1` | `Exchange Online/EXO - Mailbox Alias Management.ps1` | Manage SMTP aliases on Exchange Online mailboxes. |
| EXO-012 | `Cloud_Scripts/Exchange_Management/EXO-012_Mailbox-Audit-Flags-Management.ps1` | `Exchange Online/EXO - Mailbox Audit Flags Management.ps1` | Configure mailbox audit logging flags per mailbox. |
| EXO-013 | `Cloud_Scripts/Exchange_Management/EXO-013_Mailbox-Client-Access-Settings-Management.ps1` | `Exchange Online/EXO - Mailbox Client Access Settings Management.ps1` | Manage CAS mailbox settings (MAPI, OWA, ActiveSync, etc.). |
| EXO-014 | `Cloud_Scripts/Exchange_Management/EXO-014_Mailbox-Permission-Management.ps1` | `Exchange Online/EXO - Mailbox Permission Management.ps1` | Grant and revoke mailbox permissions (FullAccess, SendAs, SendOnBehalf). |
| EXO-015 | `Cloud_Scripts/Exchange_Management/EXO-015_Mailbox-Quota-Management.ps1` | `Exchange Online/EXO - Mailbox Quota Management.ps1` | Set and report mailbox storage quotas and warnings. |
| EXO-016 | `Cloud_Scripts/Exchange_Management/EXO-016_Mailbox-Restore-Request.ps1` | `Exchange Online/EXO - Mailbox Restore Request.ps1` | Create and monitor mailbox restore requests. |
| EXO-017 | `Cloud_Scripts/Exchange_Management/EXO-017_Mailbox-Retain-Deleted-Items-Management.ps1` | `Exchange Online/EXO - Mailbox Retain Deleted Items Management.ps1` | Configure deleted item retention per mailbox. |
| EXO-018 | `Cloud_Scripts/Exchange_Management/EXO-018_Message-Trace-External-Recipients.ps1` | `Exchange Online/EXO - Message Trace External Recipients.ps1` | Trace messages sent to external recipients. |
| EXO-019 | `Cloud_Scripts/Exchange_Management/EXO-019_Mobile-Device-Management.ps1` | `Exchange Online/EXO - Mobile Device Management.ps1` | Manage mobile device partnerships and wipe actions. |
| EXO-020 | `Cloud_Scripts/Exchange_Management/EXO-020_Office-Message-Encryption.ps1` | `Exchange Online/EXO - Office Message Encryption.ps1` | Configure and manage OME encryption policies. |
| EXO-021 | `Cloud_Scripts/Exchange_Management/EXO-021_Organization-Management.ps1` | `Exchange Online/EXO - Organization Management.ps1` | View and modify Exchange Online organization settings. |
| EXO-022 | `Cloud_Scripts/Exchange_Management/EXO-022_RBAC-Management.ps1` | `Exchange Online/EXO - RBAC.ps1` | Manage Exchange Online role-based access control. |
| EXO-023 | `Cloud_Scripts/Exchange_Management/EXO-023_Tenant-Hydration.ps1` | `Exchange Online/EXO - Tenant Hydration.ps1` | Check and trigger Exchange Online tenant hydration status. |
| EXO-024 | `Cloud_Scripts/Exchange_Management/EXO-024_Trusted-Blocked-Senders-Management.ps1` | `Exchange Online/EXO - Trusted or Blocked Senders Mailbox Management.ps1` | Manage trusted and blocked sender lists on mailboxes. |
| EXO-025 | `Cloud_Scripts/Exchange_Management/EXO-025_Unified-Groups-Hidden-From-GAL.ps1` | `Exchange Online/EXO - Unified Groups Hidden from GAL or Outlook.ps1` | Show or hide Microsoft 365 Groups from GAL and Outlook. |
| TEA-007 | `Cloud_Scripts/Teams/TEA-007_Application-Cache-Clear.ps1` | `Microsoft Teams/Teams - Application Cache Clear.ps1` | Clear Microsoft Teams application cache on endpoints. |
| TEA-008 | `Cloud_Scripts/Teams/TEA-008_Audio-Conferencing-User-Management.ps1` | `Microsoft Teams/Teams - Audio Conferencing User Management.ps1` | Assign and manage audio conferencing licenses and settings. |
| TEA-009 | `Cloud_Scripts/Teams/TEA-009_Channel-Management.ps1` | `Microsoft Teams/Teams - Channel Management.ps1` | Add, remove, and list Teams channel members. |
| TEA-010 | `Cloud_Scripts/Teams/TEA-010_Cloud-Recording-Management.ps1` | `Microsoft Teams/Teams - Cloud Recording Management.ps1` | Manage Teams cloud meeting recording policies. |
| TEA-011 | `Cloud_Scripts/Teams/TEA-011_Direct-Routing-Tenant-Overview.ps1` | `Microsoft Teams/Teams - Direct Routing Tenant Overview.ps1` | Export Direct Routing SBC and voice route configuration. |
| TEA-012 | `Cloud_Scripts/Teams/TEA-012_Direct-Routing-User-Overview.ps1` | `Microsoft Teams/Teams - Direct Routing User Overview.ps1` | Report users with Direct Routing voice configuration. |
| TEA-013 | `Cloud_Scripts/Teams/TEA-013_Enterprise-Voice.ps1` | `Microsoft Teams/Teams - Enterprise Voice.ps1` | Enterprise Voice policy and user assignment management. |
| TEA-014 | `Cloud_Scripts/Teams/TEA-014_Resource-Account-Association.ps1` | `Microsoft Teams/Teams - Resource Account Association.ps1` | Associate resource accounts with Teams applications. |
| TEA-015 | `Cloud_Scripts/Teams/TEA-015_Resource-Account-Management.ps1` | `Microsoft Teams/Teams - Resource Account Management.ps1` | Create and manage Teams resource accounts. |
| TEA-016 | `Cloud_Scripts/Teams/TEA-016_Resource-Account-Troubleshooting.ps1` | `Microsoft Teams/Teams - Resource Account Troubleshooting.ps1` | Diagnose Teams resource account and CQ/AA issues. |
| TEA-017 | `Cloud_Scripts/Teams/TEA-017_Team-Membership-Copy.ps1` | `Microsoft Teams/Teams - Team Membership Copy.ps1` | Copy team membership from one team to another. |
| TEA-018 | `Cloud_Scripts/Teams/TEA-018_Team-Overview.ps1` | `Microsoft Teams/Teams - Team Overview.ps1` | Export Teams overview including owners, members, and settings. |
| TEA-019 | `Cloud_Scripts/Teams/TEA-019_Team-Visibility-Management.ps1` | `Microsoft Teams/Teams - Team Visibility Management.ps1` | Change Teams visibility (public/private) in bulk. |
| TEA-020 | `Cloud_Scripts/Teams/TEA-020_Telephone-Number-Overview.ps1` | `Microsoft Teams/Teams - Telephone Number Overview.ps1` | Inventory assigned and unassigned telephone numbers. |
| TEA-021 | `Cloud_Scripts/Teams/TEA-021_Telephone-Number-Portability-Test.ps1` | `Microsoft Teams/Teams - Telephone Number Portability Test.ps1` | Run number portability validation tests. |
| TEA-022 | `Cloud_Scripts/Teams/TEA-022_User-Phone-Number-Management.ps1` | `Microsoft Teams/Teams - User Phone Number Management.ps1` | Assign and unassign phone numbers to Teams users. |
| TEA-023 | `Cloud_Scripts/Teams/TEA-023_Voice-Overview.ps1` | `Microsoft Teams/Teams - Voice Overview.ps1` | Full Teams voice configuration tenant overview. |
| TEA-024 | `Cloud_Scripts/Teams/TEA-024_Telephone-Number-Search-Acquire-Legacy.ps1` | `Microsoft Teams/TeamsTelephoneNumberSearchAndAcquireLegacy.ps1` | Search and acquire telephone numbers (legacy cmdlet flow). |
| TEA-025 | `Cloud_Scripts/Teams/TEA-025_Upgrade-Status-Management.ps1` | `Microsoft Teams/TeamsUpgradeStatusManagement.ps1` | Manage Skype-to-Teams upgrade status for users. |
| TEA-026 | `Cloud_Scripts/Teams/TEA-026_Voice-User-Overview.ps1` | `Microsoft Teams/TeamsVoiceUserOverview.ps1` | Export per-user Teams voice settings and policies. |
| SPO-011 | `Cloud_Scripts/SharePoint/SPO-011_OneDrive-Client-Management.ps1` | `SharePoint Online/OneDrive Client Management.ps1` | Manage OneDrive sync client settings and policies. |
| SPO-012 | `Cloud_Scripts/SharePoint/SPO-012_Site-Owner-Management.ps1` | `SharePoint Online/SPO - Site Owner Management.ps1` | Add and remove SharePoint site collection owners. |
| SPO-013 | `Cloud_Scripts/SharePoint/SPO-013_Site-Quota-Management.ps1` | `SharePoint Online/SPO - Site Quota.ps1` | View and set SharePoint site storage quotas. |
| SPO-014 | `Cloud_Scripts/SharePoint/SPO-014_Site-Sharing-Capability-Management.ps1` | `SharePoint Online/SPO - Site Sharing Capability Management.ps1` | Manage external sharing capability per site. |
| SPO-015 | `Cloud_Scripts/SharePoint/SPO-015_Document-Library-Permission-Inheritance.ps1` | `SharePoint Online/PNP/SPO-PNP - Document Library Permission Inheritance Management.ps1` | Break, restore, and audit library permission inheritance via PnP. |
| SPO-016 | `Cloud_Scripts/SharePoint/SPO-016_Recycle-Bin-Management.ps1` | `SharePoint Online/PNP/SPO-PNP - Recycle Bin Management.ps1` | Manage site and second-stage recycle bins via PnP. |
| ENT-001 | `Cloud_Scripts/Entra_ID/ENT-001_ADSync-Cycle-Management.ps1` | `Azure AD/ADSyncCycleManagement.ps1` | Start full/delta sync and configure Azure AD Connect scheduler. |
| ENT-002 | `Cloud_Scripts/Entra_ID/ENT-002_Azure-Device-Management.ps1` | `Azure AD/AzureDeviceManagement.ps1` | Manage Entra ID registered and joined devices. |
| ENT-003 | `Cloud_Scripts/Entra_ID/ENT-003_MSOL-Deleted-User-Management.ps1` | `Microsoft Online/MSOL - Deleted User Management.ps1` | List, restore, and permanently delete soft-deleted users. |
| SEC-001 | `Cloud_Scripts/Security_and_Compliance/SEC-001_AIP-Activation.ps1` | `Azure Information Protection/AIP - Activation.ps1` | Activate Azure Information Protection unified labeling. |
| SCC-001 | `Cloud_Scripts/Security_and_Compliance/SCC-001_Compliance-Search-and-Delete.ps1` | `Security & Compliance/S&C - Search and Delete.ps1` | Create compliance searches and purge matching content. |
| UTL-025 | `Cloud_Scripts/Utilities/Connection/UTL-025_Connect-M365.ps1` | `Tools/Connect-M365.ps1` | Connect to common M365 services (O365scripts variant). |
| UTL-026 | `Cloud_Scripts/Utilities/Connection/UTL-026_Connect-M365-NoMFA.ps1` | `Tools/Connect-M365NoMFA.ps1` | Connect to M365 services without MFA prompt. |
| UTL-027 | `Cloud_Scripts/Utilities/UTL-027_Get-M365-Domain-Dns-Overview.ps1` | `Tools/Get-M365DomainDnsOverview.ps1` | Export DNS records required for M365 domain validation. |
| UTL-028 | `Cloud_Scripts/Utilities/UTL-028_Get-M365-Module-Overview.ps1` | `Tools/Get-M365ModuleOverview.ps1` | List installed M365 PowerShell modules and versions. |
| UTL-029 | `Cloud_Scripts/Utilities/UTL-029_Get-M365-Teams-Upgrade-Status.ps1` | `Tools/Get-M365TeamsUpgradeStatus.ps1` | Report Skype-to-Teams upgrade status for users. |
| UTL-030 | `Cloud_Scripts/Utilities/UTL-030_Get-M365-User-Overview.ps1` | `Tools/Get-M365UserOverview.ps1` | Export comprehensive user account overview. |
| UTL-031 | `Cloud_Scripts/Utilities/UTL-031_Invoke-M365-Check-System-Requirements.ps1` | `Tools/Invoke-M365CheckSystemRequirements.ps1` | Validate PowerShell and .NET prerequisites for M365 scripts. |
| UTL-032 | `Cloud_Scripts/Utilities/UTL-032_M365-Bulk-Domain-Overview.ps1` | `Tools/M365 Bulk Domain Overview.ps1` | Bulk domain status overview across tenants. |
| UTL-033 | `Cloud_Scripts/Utilities/UTL-033_M365-DNS-Overview.ps1` | `Tools/M365 DNS Overview.ps1` | Compare tenant DNS records against Microsoft requirements. |
| UTL-034 | `Cloud_Scripts/Utilities/UTL-034_O365-System-Requirements.ps1` | `Tools/O365 - System Requirements.ps1` | Check Windows PowerShell and WMF prerequisites. |
| UTL-035 | `Cloud_Scripts/Utilities/UTL-035_Search-Email-Address.ps1` | `Tools/Search-EmailAddress.ps1` | Search for an email address across EXO recipient types. |

## Previously Integrated (Upstream Equivalents)

| Workspace Script | Upstream Original |
|------------------|-------------------|
| `Cloud_Scripts/Utilities/Connection/UTL-009_Connect-All.ps1` | `Connection/O365ConnectAll.ps1` |
| `Cloud_Scripts/Utilities/Connection/UTL-010_Connect-AzureAD.ps1` | `Connection/O365ConnectAzureActiveDirectory.ps1` |
| `Cloud_Scripts/Utilities/Connection/UTL-011_Connect-Commerce.ps1` | `Connection/O365ConnectCommerce.ps1` |
| `Cloud_Scripts/Utilities/Connection/UTL-012_Connect-Exchange-Online.ps1` | `Connection/O365ConnectExchangeOnline.ps1` |
| `Cloud_Scripts/Utilities/Connection/UTL-013_Connect-Exchange-Online-Basic-Deprecated.ps1` | `Connection/O365ConnectExchangeOnlineBasicDeprecated.ps1` |
| `Cloud_Scripts/Utilities/Connection/UTL-014_Connect-MSOnline.ps1` | `Connection/O365ConnectMicrosoftOnlineMSOL.ps1` |
| `Cloud_Scripts/Utilities/Connection/UTL-015_Connect-Teams.ps1` | `Connection/O365ConnectMicrosoftTeams.ps1` |
| `Cloud_Scripts/Utilities/Connection/UTL-016_Connect-Security-Compliance.ps1` | `Connection/O365ConnectSecurityCompliance.ps1` |
| `Cloud_Scripts/Utilities/Connection/UTL-017_Connect-SharePoint-Online.ps1` | `Connection/O365ConnectSharePointOnline.ps1` |
| `Cloud_Scripts/Utilities/Connection/UTL-018_Connect-Skype-Online-Deprecated.ps1` | `Connection/O365ConnectSkypeForBusinessOnlineDeprecated.ps1` |
| `Cloud_Scripts/Utilities/Connection/UTL-019_Connect-SharePoint-PnP.ps1` | `Connection/O365ConnectSPOPNP.ps1` |
| `Cloud_Scripts/Utilities/Common/UTL-020_Get-RandomAlphaNumString.ps1` | `Common Functions/Get-RandomAlphaNumString.ps1` |
| `Cloud_Scripts/Utilities/Common/UTL-021_Get-Timestamp.ps1` | `Common Functions/Get-Timestamp.ps1` |
| `Cloud_Scripts/Utilities/Templates/UTL-022_New-Script-Template.ps1` | `Templates/New.ps1` |
| `Cloud_Scripts/Utilities/Templates/UTL-023_New-Function-Template.ps1` | `Templates/NewFunction.ps1` |
| `Cloud_Scripts/Office_Apps/UTL-024_Office-Apps-Management.ps1` | `Office Apps/Office Apps Management.ps1` |
| `Cloud_Scripts/Exchange_Management/EXO-007_Exchange-Mailbox-Conversion.ps1` | `Exchange Online/ExchangeOnlineMailboxConversion.ps1` |
| `Cloud_Scripts/M365_Assessment/M365-019_MS-Graph-Licensing-Overview.ps1` | `Microsoft Graph/MS Graph - Licensing Overview.ps1` |
| `OnPremises_Scripts/Utilities/UTL-005_Install-PSModules.ps1` | `Tools/Install-M365Module.ps1` |
