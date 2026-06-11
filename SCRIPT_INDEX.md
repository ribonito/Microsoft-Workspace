# 📘 Microsoft Workspace – Script Index
> **All scripts are in English, organized by technology/product, and individually numbered.**
> Last updated: June 2026 | Maintainer: Josep Canas – M365 Solutions Architect

---

## Naming Convention

```
<PREFIX>-<NNN>_<ShortDescription>.ps1
```

| Prefix | Technology / Product |
|--------|----------------------|
| `EXO`  | Exchange Online / Defender for Office 365 / Partner Center |
| `SPO`  | SharePoint Online / PnP Modern |
| `TEA`  | Microsoft Teams |
| `M365` | M365 Assessment (general / cross-service) |
| `INT`  | Microsoft Intune / Autopilot / Endpoint Manager |
| `UTL`  | Utilities (multi-service, connectivity, tools) |
| `OPR`  | On-Premises infrastructure assessment |
| `MIG`  | Migration (multi-source, cross-tenant) |

---

## 📧 Exchange Online (EXO)

| # | File | Description |
|---|------|-------------|
| EXO-001 | EXO-001_ATP-Implementation.ps1 | Set up Microsoft Defender for Office 365 – Safe Attachments + Safe Links |
| EXO-002 | EXO-002_Enable-MailboxAuditing.ps1 | Enable mailbox auditing for all user mailboxes + restrict calendar sharing |
| EXO-003 | EXO-003_Block-AutoForwarding.ps1 | Block external auto-forwarding via Transport Rule |
| EXO-004 | EXO-004_Disable-SelfServicePurchase.ps1 | Disable self-service purchases for all M365 products (MSCommerce) |
| EXO-005 | EXO-005_Security-Hardening-NewTenant.ps1 | Consolidated Exchange Online security hardening for new tenant onboarding |
| EXO-006 | EXO-006_PartnerCenter-CustomerQuery.ps1 | Query CSP partner/customer data via PartnerCenter module |

---

## 📦 SharePoint Online / PnP Modern (SPO)

> All migration scripts in: `Cloud_Scripts/SharePoint/Migrations/`

| # | File | Description |
|---|------|-------------|
| SPO-001 | SPO-001_PreMigration-Assessment.ps1 | Full pre-migration inventory: sites, libraries, permissions, Hub membership |
| SPO-002 | SPO-002_SiteMigration-ClassicToModern.ps1 | Migrate classic/on-premises site to modern SPO via PnP Template |
| SPO-003 | SPO-003_TenantToTenant-Migration.ps1 | Full Tenant-to-Tenant migration (8 phases, user mapping CSV, report) |
| SPO-004 | SPO-004_HubSpoke-Provisioning.ps1 | Provision a Hub-Spoke architecture with navigation and Site Designs |
| SPO-005 | SPO-005_PostMigration-Validation.ps1 | Validate migration completeness (item counts, permissions, pages) + auto-remediate |
| SPO-006 | SPO-006_Permissions-Management.ps1 | Audit/break/restore inheritance, remove external users, replace security groups |
| SPO-007 | SPO-007_SiteDesigns-Management.ps1 | Create, apply, export and cleanup Site Designs and Site Scripts |
| SPO-008 | SPO-008_Sharepoint-Bulk-Creation.ps1 | Bulk create Microsoft Teams from a CSV template |

---

## 💬 Microsoft Teams (TEA)

| # | File | Description |
|---|------|-------------|
| TEA-001 | TEA-001_Teams-FullInventory-Report.ps1 | Full Teams report: owners, members, channels, guests, SharePoint URL |
| TEA-002 | TEA-002_Teams-UniqueMembers-Export.ps1 | Export de-duplicated list of unique users across all Teams |
| TEA-003 | TEA-003_Export-Teams-List-PnP.ps1 | Export list of Teams, channels, visibility, and owners using PnP |
| TEA-004 | TEA-004_Teams-Interactive-Assessment.ps1 | Interactive menu to audit and export Teams and channels to CSV |

---

## 📊 M365 Assessment (M365)

| # | File | Description |
|---|------|-------------|
| M365-001 | M365-001_OneDrive-StorageReport.ps1 | OneDrive for Business storage consumption report (sorted by usage) |
| M365-002 | M365-002_DL-Members-Export.ps1 | Export all Distribution List members with role and email |
| M365-003 | M365-003_Mailbox-ArchiveSize-Report.ps1 | Mailbox and archive size report for all users (sizing / migration) |
| M365-004 | M365-004_SPO-List-Inventory-CSOM.ps1 | SharePoint Online list inventory using CSOM assemblies |
| M365-005 | M365-005_Report-M365.ps1 | Generate interactive HTML report on the M365 tenant |
| M365-006 | M365-006_Security-Improvements.ps1 | Check and remediate tenant security baselines |
| M365-007 | M365-007_Export-CAPolicies.ps1 | Export Entra ID Conditional Access policies to CSV |
| M365-008 | M365-008_Reporting-Teams-Telephony.ps1 | Export Teams phone numbers by routing type |
| M365-009 | M365-009_Export-AzureADDevices.ps1 | Export Azure AD device report with BitLocker and owner info to CSV |
| M365-010 | M365-010_M365-Assessment-All.ps1 | Generate governance, data retention, compliance, and training reports |
| M365-011 | M365-011_PowerBI-Report-Inventory.ps1 | Export inventory of Power BI workspaces and reports to CSV |
| M365-012 | M365-012_M365-Licensing-SKU-Export.ps1 | Export subscribed licensing SKUs and friendly service plan names |
| M365-013 | M365-013_Mailbox-ArchiveSize-FullReport.ps1 | Detailed Exchange Online mailbox size and archive status report |
| M365-014 | M365-014_SPO-SiteUsage-GraphReport.ps1 | Call Graph Reporting API to get 30-day SPO site storage/activity |

---

## 🖥️ Microsoft Intune / Endpoint (INT)

| # | File | Description |
|---|------|-------------|
| INT-001 | INT-001_Connect-IntuneAutomation.ps1 | Authenticate to Microsoft Graph via Client Credentials (app-only) |
| INT-002 | INT-002_Backup-FullIntuneConfig.ps1 | Full Intune config backup to JSON (enrollment, Autopilot, CA, groups) |
| INT-003 | INT-003_Update-DeviceAutopilotRecord.ps1 | Update Autopilot device records (single or bulk CSV) |
| INT-004 | INT-004_Update-WindowsOSCompliancePolicy.ps1 | Auto-update Windows OS compliance policy to N-1 Patch Tuesday build |
| INT-005 | INT-005_Backup-Import-CAPolicies.ps1 | Backup and import Conditional Access policies via Microsoft Graph |
| INT-006 | INT-006_Get-Users-Last-Signins.ps1 | Retrieve users' last interactive/non-interactive sign-in logs |
| INT-007 | INT-007_Detect-Appx.ps1 | Detection script to check if specific AppX packages are installed |
| INT-008 | INT-008_Invoke-SRIntuneBackupComplianceNotificationMessageTemplates.ps1 | Backup, restore, and template Intune notification message configs |
| INT-009 | INT-009_TurnOffWindowsCopilot-Detect.ps1 | Detection: verify TurnOffWindowsCopilot is set in user registries |
| INT-010 | INT-010_TurnOffWindowsCopilot-Remediate.ps1 | Remediation: disable Windows Copilot via user registry policy |
| INT-011 | INT-011_OD-MountTimer-Detect.ps1 | Detection: check OneDrive Timerautomount registry setting |
| INT-012 | INT-012_OD-MountTimer-Remediate.ps1 | Remediation: enable OneDrive Timerautomount registry setting |
| INT-013 | INT-013_HybridComputerRename-Detect.ps1 | Detection: verify if hybrid AD computer rename has completed |
| INT-014 | INT-014_HybridComputerRename-Remediate.ps1 | Remediation: rename hybrid computer per Autopilot record |
| INT-015 | INT-015_HAADJComputerRename-App.ps1 | Win32 App: rename hybrid AD computer per Autopilot record |
| INT-016 | INT-016_Register-AutopilotDevice.ps1 | Autopilot: register device hardware hash online or export to CSV |
| INT-017 | INT-017_Reset-DeviceForAutopilot.ps1 | Autopilot: trigger remote device reset and assign properties |
| INT-018 | INT-018_Drive-Mapping.ps1 | Logon script to map network drives based on user AD groups |
| INT-019 | INT-019_Printer-Mapping.ps1 | Logon script to map network printers based on user AD groups |

---

## 🔧 Utilities (UTL)

| # | File | Description |
|---|------|-------------|
| UTL-001 | UTL-001_Connect-O365Services.ps1 | Connect to all M365 services with a single script (MFA + CBA support) |
| UTL-002 | UTL-002_M365-Cache-Cleaning.ps1 | Interactive menu to clear cache for M365 desktop apps |
| UTL-003 | UTL-003_Set-ProxyAndTLS.ps1 | Configure system proxy + enforce TLS 1.2 for PowerShell sessions |
| UTL-004 | UTL-004_Update-M365PSModules.ps1 | Update and maintain all M365 PowerShell modules, clean old versions |
| UTL-005 | UTL-005_Install-PSModules.ps1 | Bootstrapping utility to install all required M365 PowerShell modules |
| UTL-006 | UTL-006_Combine-CsvFiles.ps1 | Merge multiple Autopilot device export CSVs into a single import file |

---

## 🏢 On-Premises (OPR)

| # | File | Description |
|---|------|-------------|
| OPR-001 | OPR-001_Citrix-Assessment.ps1 | Citrix XenApp/XenDesktop 7.x published application inventory |
| OPR-002 | OPR-002_Exchange-Health-Checker.ps1 | Microsoft Exchange Server on-premises configuration and performance health check |
| OPR-003 | OPR-003_Mailbox-Assessment-Report.ps1 | Exchange Server mailbox size and statistics report |

---

## 🗂️ Migration (MIG)

| # | File | Description |
|---|------|-------------|
| MIG-001 | MIG-001_BitTitan-Statistics.ps1 | BitTitan/MigrationWiz migration statistics and reporting |

---

## Workflow Map: Recommended Execution Order

```
─── Assessment Phase ────────────────────────────────────────
  M365-001 → M365-002 → M365-003 → M365-004 → M365-009 → M365-010 → M365-011 → M365-012 → M365-013 → M365-014
  TEA-001  → TEA-002  → TEA-003  → TEA-004
  SPO-001  → SPO-006 (Audit mode)
  OPR-001  → OPR-002  → OPR-003

─── Hardening / Onboarding Phase ────────────────────────────
  EXO-005  → EXO-001 → EXO-002 → EXO-003 → EXO-004

─── Migration Phase ─────────────────────────────────────────
  SPO-002  or  SPO-003 (Tenant-to-Tenant)
  SPO-004  (Hub-Spoke architecture)
  SPO-007  (Site Designs standardisation)
  SPO-005  (Post-migration validation)
  SPO-006  (Permission remediation)

─── Intune / Endpoint Phase ─────────────────────────────────
  INT-001 → INT-002 → INT-003 → INT-004 → INT-005 → INT-006 → INT-007 → INT-008 → INT-009 → INT-010 → INT-011 → INT-012 → INT-013 → INT-014 → INT-015 → INT-016 → INT-017 → INT-018 → INT-019

─── Utilities (use as needed) ────────────────────────────────
  UTL-001 → UTL-003 → UTL-002 → UTL-004 → UTL-005 → UTL-006
```
