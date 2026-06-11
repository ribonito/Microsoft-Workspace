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
| SPO-001 | 01_SPO-PreMigration-Assessment.ps1 | Full pre-migration inventory: sites, libraries, permissions, Hub membership |
| SPO-002 | 02_SPO-SiteMigration-ClassicToModern.ps1 | Migrate classic/on-premises site to modern SPO via PnP Template |
| SPO-003 | 03_SPO-TenantToTenant-Migration.ps1 | Full Tenant-to-Tenant migration (8 phases, user mapping CSV, report) |
| SPO-004 | 04_SPO-HubSpoke-Provisioning.ps1 | Provision a Hub-Spoke architecture with navigation and Site Designs |
| SPO-005 | 05_SPO-PostMigration-Validation.ps1 | Validate migration completeness (item counts, permissions, pages) + auto-remediate |
| SPO-006 | 06_SPO-Permissions-Management.ps1 | Audit/break/restore inheritance, remove external users, replace security groups |
| SPO-007 | 07_SPO-SiteDesigns-Management.ps1 | Create, apply, export and cleanup Site Designs and Site Scripts |
| SPO-008 | Sharepoint_bulk_creation.ps1 | Bulk create Microsoft Teams from a CSV template |

---

## 💬 Microsoft Teams (TEA)

| # | File | Description |
|---|------|-------------|
| TEA-001 | TEA-001_Teams-FullInventory-Report.ps1 | Full Teams report: owners, members, channels, guests, SharePoint URL |
| TEA-002 | TEA-002_Teams-UniqueMembers-Export.ps1 | Export de-duplicated list of unique users across all Teams |

---

## 📊 M365 Assessment (M365)

| # | File | Description |
|---|------|-------------|
| M365-001 | M365-001_OneDrive-StorageReport.ps1 | OneDrive for Business storage consumption report (sorted by usage) |
| M365-002 | M365-002_DL-Members-Export.ps1 | Export all Distribution List members with role and email |
| M365-003 | M365-003_Mailbox-ArchiveSize-Report.ps1 | Mailbox and archive size report for all users (sizing / migration) |
| M365-004 | M365-004_SPO-List-Inventory-CSOM.ps1 | SharePoint Online list inventory using CSOM assemblies |

> Additional assessment scripts (larger, complex): `reportM365.ps1`, `Sec_improvements.ps1`, `ExportCAPolicies.ps1`, `Reporting_Teams-Telephony.ps1` in `M365_Assessment/`

---

## 🖥️ Microsoft Intune / Endpoint (INT)

| # | File | Description |
|---|------|-------------|
| INT-001 | INT-001_Connect-IntuneAutomation.ps1 | Authenticate to Microsoft Graph via Client Credentials (app-only) |
| INT-002 | Backup-FullIntuneConfig.ps1 | Full Intune config backup to JSON (enrollment, Autopilot, CA, groups) |
| INT-003 | Update-DeviceAutopilotRecord.ps1 | Update Autopilot device records (single or bulk CSV) |
| INT-004 | Update-WindowsOSCompliancePolicy.ps1 | Auto-update Windows OS compliance policy to N-1 Patch Tuesday build |

---

## 🔧 Utilities (UTL)

| # | File | Description |
|---|------|-------------|
| UTL-001 | ConnectO365Services.ps1 | Connect to all M365 services with a single script (MFA + CBA support) |
| UTL-002 | m365cachecleaning.ps1 | Interactive menu to clear cache for M365 desktop apps |
| UTL-003 | UTL-003_Set-ProxyAndTLS.ps1 | Configure system proxy + enforce TLS 1.2 for PowerShell sessions |

---

## 🏢 On-Premises (OPR)

| # | File | Description |
|---|------|-------------|
| OPR-001 | citrix_assessment.ps1 | Citrix XenApp/XenDesktop 7.x published application inventory |

> Exchange on-premises: see `OnPremises_Scripts/Exchange_Management/` for `HealthChecker.ps1` and `Mailbox_assestment.ps1`

---

## 🗂️ Migration (MIG)

| # | File | Description |
|---|------|-------------|
| MIG-001 | bittitan_statistics.ps1 | BitTitan/MigrationWiz migration statistics and reporting |

---

## Workflow Map: Recommended Execution Order

```
─── Assessment Phase ────────────────────────────────────────
  M365-001 → M365-002 → M365-003 → M365-004
  TEA-001  → TEA-002
  SPO-001  → SPO-006 (Audit mode)

─── Hardening / Onboarding Phase ────────────────────────────
  EXO-005  → EXO-001 → EXO-002 → EXO-003 → EXO-004

─── Migration Phase ─────────────────────────────────────────
  SPO-002  or  SPO-003 (Tenant-to-Tenant)
  SPO-004  (Hub-Spoke architecture)
  SPO-007  (Site Designs standardisation)
  SPO-005  (Post-migration validation)
  SPO-006  (Permission remediation)

─── Intune / Endpoint Phase ─────────────────────────────────
  INT-001 → INT-002 → INT-003 → INT-004

─── Utilities (use as needed) ────────────────────────────────
  UTL-001 → UTL-003 → UTL-002
```
