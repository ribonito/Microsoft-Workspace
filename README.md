# Workspace Technology Overview

Welcome to the **Workspace Technology** repository! This project serves as a central hub for scripts, configuration templates, reports, and documentation related to Microsoft 365 (M365), Azure, and Intune.

The workspace is split into two primary environments: **☁️ Cloud Scripts** and **🏢 On-Premises Scripts**, alongside supporting governance, reporting, and templating directories.

---

## 📂 Repository Structure

The repository is organized into distinct, specialized directories to ensure high maintainability, cleanliness, and ease of access:

* `Cloud_Scripts/` - Cloud-native configuration and management tools.
  * `Azure/` - Cloud resources monitoring (e.g., Azure Monitor Alerts common schema).
  * `Exchange_Management/` - Exchange Online security configurations, auditing, and mail-flow hardening.
  * `Intune/` - Cloud Intune configuration backups, Graph connections, and Win32 application packaging source trees.
  * `M365_Assessment/` - Comprehensive tools and scripts for assessing Microsoft 365 tenants (licensing, SPO, Teams, and overall security).
  * `Migration/` - BitTitan MigrationWiz statistics and migration error reporting tools.
  * `SharePoint/` - Bulk site provisioning and Teams creation automation.
  * `Utilities/` - Multi-service O365 connection establishing helper.
* `OnPremises_Scripts/` - Client-side, Active Directory Domain Services, and on-premises infrastructure scripts.
  * `Exchange_Management/` - Hybrid Exchange synchronization enabling helper and Exchange 2019 / SE assessment/health checks.
  * `Intune/` - Client endpoint configuration scripts (drive maps, printer maps, HAADJ renames, and client security settings).
  * `M365_Assessment/` - On-premises virtualization auditing (Citrix desktop inventory).
  * `Utilities/` - Client networking configurations (system-wide proxy setup) and local M365 desktop app cache clearers.
* `Governance_and_Policies/` - Organizational frameworks, data management policies, training details, and best practices.
* `Reports/` - Generated tenant status spreadsheets, Teams rosters, audit logs, and mailbox size lists.
* `Templates/` - Design baselines (e.g., Entra ID Conditional Access JSON files) and CSV templates.

---



---

## 🚀 Getting Started

Most of the tools here are **PowerShell scripts** (`.ps1`). To execute them:
1. Open PowerShell 7+ or Windows PowerShell (run as Administrator if installing modules).
2. Configure execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process`.
3. To automatically connect to all necessary M365 modules, use the multi-service utility helper:
   ```powershell
   ./Cloud_Scripts/Utilities/ConnectO365Services.ps1
   ```

---

## 🔒 Security Best Practices

Ensure that you do not commit active credentials, tenant secrets, or sensitive customer information back to version control. Always utilize temporary sessions or certificate-based authentication as outlined in the connection utilities.
