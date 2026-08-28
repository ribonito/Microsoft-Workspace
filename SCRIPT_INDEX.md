# 📘 Microsoft Workspace – Script Index
> **All scripts are in English, organized by technology/product, and individually numbered.**
> Last updated: August 2026 | Maintainer: Josep Canas – M365 Solutions Architect
> O365scripts upstream integration: see [O365SCRIPTS_MAP.md](O365SCRIPTS_MAP.md)

---

## Naming Convention

```
<PREFIX>-<NNN>_<ShortDescription>.ps1
```

| Prefix | Technology / Product |
|--------|----------------------|
| `EXO`  | Exchange Online / Defender for Office 365 |
| `SPO`  | SharePoint Online / PnP Modern |
| `TEA`  | Microsoft Teams |
| `ENT`  | Entra ID / Azure AD Connect / Identity |
| `M365` | M365 Assessment (cross-service / Graph) |
| `INT`  | Microsoft Intune / Autopilot / Endpoint Manager |
| `UTL`  | Utilities (connectivity, modules, helpers) |
| `SEC`  | Azure Information Protection |
| `SCC`  | Security & Compliance / Purview |
| `OPR`  | On-Premises infrastructure |
| `MIG`  | Migration (BitTitan, cross-tenant) |

---

## 📧 Exchange Online (EXO)

> Path: `Cloud_Scripts/Exchange_Management/`

| # | File | Description |
|---|------|-------------|
| EXO-001 | `Cloud_Scripts/Exchange_Management/EXO-001_ATP-Implementation.ps1` | Exchange Online - Enable Microsoft Defender for Office 365 (ATP) |
| EXO-002 | `Cloud_Scripts/Exchange_Management/EXO-002_Enable-MailboxAuditing.ps1` | Exchange Online - Enable Mailbox Auditing for All User Mailboxes |
| EXO-003 | `Cloud_Scripts/Exchange_Management/EXO-003_Block-AutoForwarding.ps1` | Exchange Online - Block External Auto-Forwarding via Transport Rule |
| EXO-004 | `Cloud_Scripts/Exchange_Management/EXO-004_Disable-SelfServicePurchase.ps1` | Exchange Online - Disable Self-Service Purchases for All Products |
| EXO-005 | `Cloud_Scripts/Exchange_Management/EXO-005_Security-Hardening-NewTenant.ps1` | Exchange Online - Security Hardening for New Tenant Onboarding |
| EXO-006 | `Cloud_Scripts/Exchange_Management/EXO-006_PartnerCenter-CustomerQuery.ps1` | Partner Center - Query Customer and Billing Information via PartnerCenter Module |
| EXO-007 | `Cloud_Scripts/Exchange_Management/EXO-007_Exchange-Mailbox-Conversion.ps1` | Exchange Online Mailbox Type Conversion Management |
| EXO-008 | `Cloud_Scripts/Exchange_Management/EXO-008_Distribution-Group-Management.ps1` | Distribution Group Management |
| EXO-009 | `Cloud_Scripts/Exchange_Management/EXO-009_Distribution-Group-Member-Management.ps1` | Distribution Group Member Management |
| EXO-010 | `Cloud_Scripts/Exchange_Management/EXO-010_Distribution-Groups.ps1` | Distribution Groups |
| EXO-011 | `Cloud_Scripts/Exchange_Management/EXO-011_Mailbox-Alias-Management.ps1` | Mailbox Alias Management |
| EXO-012 | `Cloud_Scripts/Exchange_Management/EXO-012_Mailbox-Audit-Flags-Management.ps1` | Mailbox Audit Flags Management |
| EXO-013 | `Cloud_Scripts/Exchange_Management/EXO-013_Mailbox-Client-Access-Settings-Management.ps1` | Mailbox Client Access Settings Management |
| EXO-014 | `Cloud_Scripts/Exchange_Management/EXO-014_Mailbox-Permission-Management.ps1` | Mailbox Permission Management |
| EXO-015 | `Cloud_Scripts/Exchange_Management/EXO-015_Mailbox-Quota-Management.ps1` | Mailbox Quota Management |
| EXO-016 | `Cloud_Scripts/Exchange_Management/EXO-016_Mailbox-Restore-Request.ps1` | Mailbox Restore Request |
| EXO-017 | `Cloud_Scripts/Exchange_Management/EXO-017_Mailbox-Retain-Deleted-Items-Management.ps1` | Mailbox Retain Deleted Items Management |
| EXO-018 | `Cloud_Scripts/Exchange_Management/EXO-018_Message-Trace-External-Recipients.ps1` | Message Trace External Recipients |
| EXO-019 | `Cloud_Scripts/Exchange_Management/EXO-019_Mobile-Device-Management.ps1` | Mobile Device Management |
| EXO-020 | `Cloud_Scripts/Exchange_Management/EXO-020_Office-Message-Encryption.ps1` | Office Message Encryption |
| EXO-021 | `Cloud_Scripts/Exchange_Management/EXO-021_Organization-Management.ps1` | Organization Management |
| EXO-022 | `Cloud_Scripts/Exchange_Management/EXO-022_RBAC-Management.ps1` | RBAC Management |
| EXO-023 | `Cloud_Scripts/Exchange_Management/EXO-023_Tenant-Hydration.ps1` | Tenant Hydration |
| EXO-024 | `Cloud_Scripts/Exchange_Management/EXO-024_Trusted-Blocked-Senders-Management.ps1` | Trusted or Blocked Senders Management |
| EXO-025 | `Cloud_Scripts/Exchange_Management/EXO-025_Unified-Groups-Hidden-From-GAL.ps1` | Unified Groups Hidden from GAL |

---

## 📦 SharePoint Online / PnP Modern (SPO)

> Path: `Cloud_Scripts/SharePoint/`, `Cloud_Scripts/SharePoint/Migrations/`

| # | File | Description |
|---|------|-------------|
| SPO-001 | `Cloud_Scripts/SharePoint/Migrations/SPO-001_PreMigration-Assessment.ps1` | SharePoint Online - Pre-Migration Assessment |
| SPO-002 | `Cloud_Scripts/SharePoint/Migrations/SPO-002_SiteMigration-ClassicToModern.ps1` | SharePoint Online - Site Migration Classic to Modern |
| SPO-003 | `Cloud_Scripts/SharePoint/Migrations/SPO-003_TenantToTenant-Migration.ps1` | SharePoint Online - Tenant-to-Tenant (T2T) Site Migration |
| SPO-004 | `Cloud_Scripts/SharePoint/Migrations/SPO-004_HubSpoke-Provisioning.ps1` | SharePoint Online - Provisioning PnP Templates for Hub-Spoke Architectures |
| SPO-005 | `Cloud_Scripts/SharePoint/Migrations/SPO-005_PostMigration-Validation.ps1` | SharePoint Online - Post-Migration Validation and Remediation |
| SPO-006 | `Cloud_Scripts/SharePoint/Migrations/SPO-006_Permissions-Management.ps1` | SharePoint Online - Bulk Permissions Management during Migration |
| SPO-007 | `Cloud_Scripts/SharePoint/Migrations/SPO-007_SiteDesigns-Management.ps1` | SharePoint Online - Bulk Creation and Deployment of Site Designs with PnP |
| SPO-008 | `Cloud_Scripts/SharePoint/SPO-008_Sharepoint-Bulk-Creation.ps1` | SharePoint Online / Microsoft Teams - Bulk Create Teams from CSV |
| SPO-009 | `Cloud_Scripts/SharePoint/Migrations/SPO-009_Migration-CheckFiles-Scan.ps1` | Scan and Log Local Files for SharePoint Online Migration |
| SPO-010 | `Cloud_Scripts/SharePoint/Migrations/SPO-010_Migration-CheckFiles-Analyze.ps1` | Analyze Logged Files for SharePoint Online Migration Compatibility |
| SPO-011 | `Cloud_Scripts/SharePoint/SPO-011_OneDrive-Client-Management.ps1` | OneDrive Client Management |
| SPO-012 | `Cloud_Scripts/SharePoint/SPO-012_Site-Owner-Management.ps1` | Site Owner Management |
| SPO-013 | `Cloud_Scripts/SharePoint/SPO-013_Site-Quota-Management.ps1` | Site Quota Management |
| SPO-014 | `Cloud_Scripts/SharePoint/SPO-014_Site-Sharing-Capability-Management.ps1` | Site Sharing Capability Management |
| SPO-015 | `Cloud_Scripts/SharePoint/SPO-015_Document-Library-Permission-Inheritance.ps1` | Document Library Permission Inheritance |
| SPO-016 | `Cloud_Scripts/SharePoint/SPO-016_Recycle-Bin-Management.ps1` | Recycle Bin Management |

---

## 💬 Microsoft Teams (TEA)

> Path: `Cloud_Scripts/Teams/`

| # | File | Description |
|---|------|-------------|
| TEA-001 | `Cloud_Scripts/Teams/TEA-001_Teams-FullInventory-Report.ps1` | Microsoft Teams - Full Teams Inventory Report |
| TEA-002 | `Cloud_Scripts/Teams/TEA-002_Teams-UniqueMembers-Export.ps1` | Microsoft Teams - Export All Unique Team Members Across All Teams |
| TEA-003 | `Cloud_Scripts/Teams/TEA-003_Export-Teams-List-PnP.ps1` | Microsoft Teams - Export Teams List using PnP PowerShell |
| TEA-004 | `Cloud_Scripts/Teams/TEA-004_Teams-Interactive-Assessment.ps1` | Microsoft Teams - Interactive Teams and Channels Assessment Tool |
| TEA-005 | `Cloud_Scripts/Teams/TEA-005_Set-Teams-Retention-Policy.ps1` | Set Microsoft Teams Information Retention Policy |
| TEA-006 | `Cloud_Scripts/Teams/TEA-006_Get-Skype-Conferencing-Policies.ps1` | Export Skype for Business / Microsoft Teams Conferencing Policies |
| TEA-007 | `Cloud_Scripts/Teams/TEA-007_Application-Cache-Clear.ps1` | Application Cache Clear |
| TEA-008 | `Cloud_Scripts/Teams/TEA-008_Audio-Conferencing-User-Management.ps1` | Audio Conferencing User Management |
| TEA-009 | `Cloud_Scripts/Teams/TEA-009_Channel-Management.ps1` | Channel Management |
| TEA-010 | `Cloud_Scripts/Teams/TEA-010_Cloud-Recording-Management.ps1` | Cloud Recording Management |
| TEA-011 | `Cloud_Scripts/Teams/TEA-011_Direct-Routing-Tenant-Overview.ps1` | Direct Routing Tenant Overview |
| TEA-012 | `Cloud_Scripts/Teams/TEA-012_Direct-Routing-User-Overview.ps1` | Direct Routing User Overview |
| TEA-013 | `Cloud_Scripts/Teams/TEA-013_Enterprise-Voice.ps1` | Enterprise Voice |
| TEA-014 | `Cloud_Scripts/Teams/TEA-014_Resource-Account-Association.ps1` | Resource Account Association |
| TEA-015 | `Cloud_Scripts/Teams/TEA-015_Resource-Account-Management.ps1` | Resource Account Management |
| TEA-016 | `Cloud_Scripts/Teams/TEA-016_Resource-Account-Troubleshooting.ps1` | Resource Account Troubleshooting |
| TEA-017 | `Cloud_Scripts/Teams/TEA-017_Team-Membership-Copy.ps1` | Team Membership Copy |
| TEA-018 | `Cloud_Scripts/Teams/TEA-018_Team-Overview.ps1` | Team Overview |
| TEA-019 | `Cloud_Scripts/Teams/TEA-019_Team-Visibility-Management.ps1` | Team Visibility Management |
| TEA-020 | `Cloud_Scripts/Teams/TEA-020_Telephone-Number-Overview.ps1` | Telephone Number Overview |
| TEA-021 | `Cloud_Scripts/Teams/TEA-021_Telephone-Number-Portability-Test.ps1` | Telephone Number Portability Test |
| TEA-022 | `Cloud_Scripts/Teams/TEA-022_User-Phone-Number-Management.ps1` | User Phone Number Management |
| TEA-023 | `Cloud_Scripts/Teams/TEA-023_Voice-Overview.ps1` | Voice Overview |
| TEA-024 | `Cloud_Scripts/Teams/TEA-024_Telephone-Number-Search-Acquire-Legacy.ps1` | Telephone Number Search and Acquire (Legacy) |
| TEA-025 | `Cloud_Scripts/Teams/TEA-025_Upgrade-Status-Management.ps1` | Upgrade Status Management |
| TEA-026 | `Cloud_Scripts/Teams/TEA-026_Voice-User-Overview.ps1` | Voice User Overview |

---

## 🔐 Entra ID (Identity) (ENT)

> Path: `Cloud_Scripts/Entra_ID/`

| # | File | Description |
|---|------|-------------|
| ENT-001 | `Cloud_Scripts/Entra_ID/ENT-001_ADSync-Cycle-Management.ps1` | ADSync Cycle Management |
| ENT-002 | `Cloud_Scripts/Entra_ID/ENT-002_Azure-Device-Management.ps1` | Azure Device Management |
| ENT-003 | `Cloud_Scripts/Entra_ID/ENT-003_MSOL-Deleted-User-Management.ps1` | MSOL Deleted User Management |

---

## 📊 M365 Assessment (M365)

> Path: `Cloud_Scripts/M365_Assessment/`

| # | File | Description |
|---|------|-------------|
| M365-001 | `Cloud_Scripts/M365_Assessment/M365-001_OneDrive-StorageReport.ps1` | M365 Assessment - OneDrive for Business Storage Consumption Report |
| M365-002 | `Cloud_Scripts/M365_Assessment/M365-002_DL-Members-Export.ps1` | M365 Assessment - Exchange Distribution List Members Export |
| M365-003 | `Cloud_Scripts/M365_Assessment/M365-003_Mailbox-ArchiveSize-Report.ps1` | M365 Assessment - Mailbox and Archive Size Report |
| M365-004 | `Cloud_Scripts/M365_Assessment/M365-004_SPO-List-Inventory-CSOM.ps1` | M365 Assessment - SharePoint Online Site List Inventory (CSOM) |
| M365-005 | `Cloud_Scripts/M365_Assessment/M365-005_Report-M365.ps1` | M365 Assessment - Interactive Tenant Report Generator (HTML) |
| M365-006 | `Cloud_Scripts/M365_Assessment/M365-006_Security-Improvements.ps1` | M365 Assessment - Tenant Security Baselines Check and Remediation |
| M365-007 | `Cloud_Scripts/Entra_ID/M365-007_Export-CAPolicies.ps1` | M365 Assessment - Export Conditional Access Policies to CSV |
| M365-008 | `Cloud_Scripts/M365_Assessment/M365-008_Reporting-Teams-Telephony.ps1` | M365 Assessment - Export Teams Telephony Numbers by Type |
| M365-009 | `Cloud_Scripts/Entra_ID/M365-009_Export-AzureADDevices.ps1` | Entra ID / Microsoft Graph - Export Azure AD Devices Report |
| M365-010 | `Cloud_Scripts/M365_Assessment/M365-010_M365-Assessment-All.ps1` | M365 - Run All Assessment Tasks and Export Governance/Compliance Reports |
| M365-011 | `Cloud_Scripts/M365_Assessment/M365-011_PowerBI-Report-Inventory.ps1` | Power BI - Export Power BI Report Inventory |
| M365-012 | `Cloud_Scripts/M365_Assessment/M365-012_M365-Licensing-SKU-Export.ps1` | M365 Assessment - Export M365 Licensing SKUs and Service Plans to CSV via Microsoft Graph |
| M365-013 | `Cloud_Scripts/M365_Assessment/M365-013_Mailbox-ArchiveSize-FullReport.ps1` | M365 Assessment - Mailbox and Archive Size Report (Full, with Shared Mailboxes) |
| M365-014 | `Cloud_Scripts/M365_Assessment/M365-014_SPO-SiteUsage-GraphReport.ps1` | M365 Assessment - SharePoint Online Site Usage Report via Microsoft Graph (App Auth) |
| M365-015 | `Cloud_Scripts/M365_Assessment/M365-015_Delete-Group-Azure-Function.ps1` | Delete Microsoft 365 / Office 365 Group via Azure Function |
| M365-016 | `Cloud_Scripts/M365_Assessment/M365-016_Provision-Group-Azure-Function.ps1` | Provision Microsoft 365 / Office 365 Group via Azure Function |
| M365-017 | `Cloud_Scripts/M365_Assessment/M365-017_Export-Unified-Groups-Report.ps1` | Export Unified Groups and Associated SharePoint Site Report |
| M365-018 | `Cloud_Scripts/M365_Assessment/M365-018_Export-User-Licenses-MSOnline.ps1` | Export Users, Licenses, and Service Plans Inventory to CSV |
| M365-019 | `Cloud_Scripts/M365_Assessment/M365-019_MS-Graph-Licensing-Overview.ps1` | Microsoft Graph Licensing and Service Plans Overview |

---

## 🖥️ Microsoft Intune / Endpoint (INT)

> Path: `Cloud_Scripts/Intune/Scripts/`, `OnPremises_Scripts/Intune/`, `OnPremises_Scripts/Intune/EndpointScripts/`

| # | File | Description |
|---|------|-------------|
| INT-001 | `Cloud_Scripts/Intune/Scripts/INT-001_Connect-IntuneAutomation.ps1` | Intune / Microsoft Graph - Automated Connection via Client Credentials |
| INT-002 | `Cloud_Scripts/Intune/Scripts/INT-002_Backup-FullIntuneConfig.ps1` | Intune - Full Intune Configuration Backup to JSON |
| INT-003 | `Cloud_Scripts/Intune/Scripts/INT-003_Update-DeviceAutopilotRecord.ps1` | Intune / Autopilot - Update Autopilot Device Record (single or bulk via CSV) |
| INT-004 | `Cloud_Scripts/Intune/Scripts/INT-004_Update-WindowsOSCompliancePolicy.ps1` | Intune - Update Windows OS Compliance Policy to N-1 Patch Tuesday Build |
| INT-005 | `Cloud_Scripts/Intune/Scripts/INT-005_Backup-Import-CAPolicies.ps1` | Intune / Entra ID - Backup and Import Conditional Access Policies via Microsoft Graph |
| INT-006 | `Cloud_Scripts/Intune/Scripts/INT-006_Get-Users-Last-Signins.ps1` | Intune / Entra ID - Export All Users' Last Sign-In Date to CSV |
| INT-007 | `Cloud_Scripts/Intune/Scripts/INT-007_Detect-Appx.ps1` | Intune Proactive Remediation - DETECT: Company Portal (AppX) Presence |
| INT-008 | `Cloud_Scripts/Intune/Scripts/INT-008_Invoke-SRIntuneBackupComplianceNotificationMessageTemplates.ps1` | Intune - Backup Compliance Policy Notification Message Templates to JSON |
| INT-009 | `OnPremises_Scripts/Intune/INT-009_TurnOffWindowsCopilot-Detect.ps1` | Intune Proactive Remediation - DETECT: Turn Off Windows Copilot (All User Profiles) |
| INT-010 | `OnPremises_Scripts/Intune/INT-010_TurnOffWindowsCopilot-Remediate.ps1` | Intune Proactive Remediation - REMEDIATE: Turn Off Windows Copilot (All User Profiles) |
| INT-011 | `OnPremises_Scripts/Intune/INT-011_OD-MountTimer-Detect.ps1` | Intune Proactive Remediation - DETECT: OneDrive Timer Automount Registry Setting |
| INT-012 | `OnPremises_Scripts/Intune/INT-012_OD-MountTimer-Remediate.ps1` | Intune Proactive Remediation - REMEDIATE: Set OneDrive Timer Automount Registry Value |
| INT-013 | `OnPremises_Scripts/Intune/INT-013_HybridComputerRename-Detect.ps1` | Intune Proactive Remediation - DETECT: Hybrid AD Joined Device Rename Completion |
| INT-014 | `OnPremises_Scripts/Intune/INT-014_HybridComputerRename-Remediate.ps1` | Intune Proactive Remediation - REMEDIATE: Rename Hybrid AD Joined Device per Autopilot Record |
| INT-015 | `OnPremises_Scripts/Intune/INT-015_HAADJComputerRename-App.ps1` | Intune Win32 App - Rename HAADJ (Entra-Joined) Device per Autopilot Record |
| INT-016 | `OnPremises_Scripts/Intune/INT-016_Register-AutopilotDevice.ps1` | Intune / Autopilot - Register a Device in Windows Autopilot (Hardware Hash Upload) |
| INT-017 | `OnPremises_Scripts/Intune/INT-017_Reset-DeviceForAutopilot.ps1` | Intune / Autopilot - Reset Device and Update Autopilot Record for Re-Provisioning |
| INT-018 | `OnPremises_Scripts/Intune/EndpointScripts/INT-018_Drive-Mapping.ps1` | Intune Endpoint Script - Map Network Drives at User Logon (JSON-driven, Group-filtered) |
| INT-019 | `OnPremises_Scripts/Intune/EndpointScripts/INT-019_Printer-Mapping.ps1` | Intune Endpoint Script - Map Network Printers at User Logon (JSON-driven, Group-filtered) |

---

## 🔧 Utilities (UTL)

> Path: `Cloud_Scripts/Utilities/`, `Cloud_Scripts/Utilities/Connection/`, `Cloud_Scripts/Utilities/Common/`, `Cloud_Scripts/Utilities/Templates/`, `OnPremises_Scripts/Utilities/`

| # | File | Description |
|---|------|-------------|
| UTL-001 | `Cloud_Scripts/Utilities/UTL-001_Connect-O365Services.ps1` | Utility - Connect to All Microsoft 365 Services with a Single Script |
| UTL-002 | `OnPremises_Scripts/Utilities/UTL-002_M365-Cache-Cleaning.ps1` | Utility - Clear Cache for Microsoft 365 Applications (Interactive) |
| UTL-003 | `OnPremises_Scripts/Utilities/UTL-003_Set-ProxyAndTLS.ps1` | Utility - Configure System Proxy and Force TLS 1.2 for PowerShell Sessions |
| UTL-004 | `Cloud_Scripts/Utilities/UTL-004_Update-M365PSModules.ps1` | Utility - Update and Maintain All Microsoft 365 PowerShell Modules |
| UTL-005 | `OnPremises_Scripts/Utilities/UTL-005_Install-PSModules.ps1` | Utility - Install All Required Microsoft 365 PowerShell Modules |
| UTL-006 | `OnPremises_Scripts/Utilities/UTL-006_Combine-CsvFiles.ps1` | Utility - Merge Multiple CSV Files into a Single Autopilot Import CSV |
| UTL-007 | `Cloud_Scripts/Utilities/UTL-007_Get-Daily-Bing-Picture.ps1` | Download and Automate Daily Bing Wallpaper for Microsoft Teams Backgrounds |
| UTL-008 | `Cloud_Scripts/Utilities/Connection/UTL-008_Connect-Exchange-SPO-Legacy.ps1` | Establish Legacy Connections to Exchange Online and SharePoint Online |
| UTL-009 | `Cloud_Scripts/Utilities/Connection/UTL-009_Connect-All.ps1` | Connect to all Office 365 / Microsoft 365 PowerShell Services |
| UTL-010 | `Cloud_Scripts/Utilities/Connection/UTL-010_Connect-AzureAD.ps1` | Connect to Entra ID / Azure Active Directory v2 |
| UTL-011 | `Cloud_Scripts/Utilities/Connection/UTL-011_Connect-Commerce.ps1` | Connect to Microsoft 365 Commerce |
| UTL-012 | `Cloud_Scripts/Utilities/Connection/UTL-012_Connect-Exchange-Online.ps1` | Connect to Exchange Online PowerShell |
| UTL-013 | `Cloud_Scripts/Utilities/Connection/UTL-013_Connect-Exchange-Online-Basic-Deprecated.ps1` | Connect to Exchange Online using Basic Authentication (Deprecated) |
| UTL-014 | `Cloud_Scripts/Utilities/Connection/UTL-014_Connect-MSOnline.ps1` | Connect to Microsoft Online (MSOnline) Service |
| UTL-015 | `Cloud_Scripts/Utilities/Connection/UTL-015_Connect-Teams.ps1` | Connect to Microsoft Teams PowerShell |
| UTL-016 | `Cloud_Scripts/Utilities/Connection/UTL-016_Connect-Security-Compliance.ps1` | Connect to Security & Compliance Center PowerShell |
| UTL-017 | `Cloud_Scripts/Utilities/Connection/UTL-017_Connect-SharePoint-Online.ps1` | Connect to SharePoint Online PowerShell |
| UTL-018 | `Cloud_Scripts/Utilities/Connection/UTL-018_Connect-Skype-Online-Deprecated.ps1` | Connect to Skype for Business Online (Deprecated) |
| UTL-019 | `Cloud_Scripts/Utilities/Connection/UTL-019_Connect-SharePoint-PnP.ps1` | Connect to SharePoint Online using PnP PowerShell |
| UTL-020 | `Cloud_Scripts/Utilities/Common/UTL-020_Get-RandomAlphaNumString.ps1` | Generate a Random Alphanumeric String |
| UTL-021 | `Cloud_Scripts/Utilities/Common/UTL-021_Get-Timestamp.ps1` | Generate a Date-Time Timestamp String |
| UTL-022 | `Cloud_Scripts/Utilities/Templates/UTL-022_New-Script-Template.ps1` | PowerShell Script Template |
| UTL-023 | `Cloud_Scripts/Utilities/Templates/UTL-023_New-Function-Template.ps1` | PowerShell Advanced Function Template |
| UTL-024 | `Cloud_Scripts/Office_Apps/UTL-024_Office-Apps-Management.ps1` | Office Apps Activation and Version Update Management |
| UTL-025 | `Cloud_Scripts/Utilities/Connection/UTL-025_Connect-M365.ps1` | Connect M365 |
| UTL-026 | `Cloud_Scripts/Utilities/Connection/UTL-026_Connect-M365-NoMFA.ps1` | Connect M365 No MFA |
| UTL-027 | `Cloud_Scripts/Utilities/UTL-027_Get-M365-Domain-Dns-Overview.ps1` | M365 Domain DNS Overview |
| UTL-028 | `Cloud_Scripts/Utilities/UTL-028_Get-M365-Module-Overview.ps1` | M365 Module Overview |
| UTL-029 | `Cloud_Scripts/Utilities/UTL-029_Get-M365-Teams-Upgrade-Status.ps1` | M365 Teams Upgrade Status |
| UTL-030 | `Cloud_Scripts/Utilities/UTL-030_Get-M365-User-Overview.ps1` | M365 User Overview |
| UTL-031 | `Cloud_Scripts/Utilities/UTL-031_Invoke-M365-Check-System-Requirements.ps1` | M365 System Requirements Check |
| UTL-032 | `Cloud_Scripts/Utilities/UTL-032_M365-Bulk-Domain-Overview.ps1` | M365 Bulk Domain Overview |
| UTL-033 | `Cloud_Scripts/Utilities/UTL-033_M365-DNS-Overview.ps1` | M365 DNS Overview |
| UTL-034 | `Cloud_Scripts/Utilities/UTL-034_O365-System-Requirements.ps1` | O365 System Requirements |
| UTL-035 | `Cloud_Scripts/Utilities/UTL-035_Search-Email-Address.ps1` | Search Email Address |

---

## 🛡️ Security (Information Protection) (SEC)

> Path: `Cloud_Scripts/Security_and_Compliance/`

| # | File | Description |
|---|------|-------------|
| SEC-001 | `Cloud_Scripts/Security_and_Compliance/SEC-001_AIP-Activation.ps1` | AIP Activation |

---

## 🔒 Security & Compliance (Purview) (SCC)

> Path: `Cloud_Scripts/Security_and_Compliance/`

| # | File | Description |
|---|------|-------------|
| SCC-001 | `Cloud_Scripts/Security_and_Compliance/SCC-001_Compliance-Search-and-Delete.ps1` | Compliance Search and Delete |

---

## 🏢 On-Premises (OPR)

> Path: `OnPremises_Scripts/`

| # | File | Description |
|---|------|-------------|
| OPR-001 | `OnPremises_Scripts/OPR-001_Citrix-Assessment.ps1` | On-Premises - Citrix XenApp/XenDesktop 7.x Inventory |
| OPR-002 | `OnPremises_Scripts/Exchange_Management/Exchange 2019 or SE Assestment/OPR-002_Exchange-Health-Checker.ps1` | Exchange Server - On-Premises Exchange Health Checker |
| OPR-003 | `OnPremises_Scripts/Exchange_Management/Exchange 2019 or SE Assestment/OPR-003_Mailbox-Assessment-Report.ps1` | Exchange Server - On-Premises Mailbox Size and Statistics Report |

---

## 🗂️ Migration (MIG)

> Path: `Cloud_Scripts/Migration/`

| # | File | Description |
|---|------|-------------|
| MIG-001 | `Cloud_Scripts/Migration/MIG-001_BitTitan-Statistics.ps1` | Migration - BitTitan/MigrationWiz Statistics and Error Reporting |

---

## Summary

**Total indexed scripts:** 149

## Workflow Map: Recommended Execution Order

```
─── Assessment Phase ────────────────────────────────────────
  M365-001 → M365-019 | M365-007 (Entra ID) | ENT-002
  TEA-001 → TEA-004, TEA-018, TEA-023 | SPO-001 → SPO-010
  OPR-001 → OPR-003

─── Hardening / Onboarding Phase ────────────────────────────
  EXO-005 → EXO-001 → EXO-004 → EXO-020

─── Migration Phase ─────────────────────────────────────────
  SPO-002 or SPO-003 → SPO-004 → SPO-007 → SPO-005 → SPO-006

─── Teams Voice Phase ───────────────────────────────────────
  TEA-011 → TEA-012 → TEA-020 → TEA-022 → TEA-023

─── Intune / Endpoint Phase ─────────────────────────────────
  INT-001 → INT-008 → INT-009 → INT-019

─── Utilities (use as needed) ────────────────────────────────
  UTL-001 → UTL-005 → UTL-009 → UTL-035
```
