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

## 📜 Script Index

All scripts are categorized physically and programmatically into two top-level directories:

### ☁️ Cloud Scripts (`Cloud_Scripts/`)
These scripts target cloud-hosted services (e.g., Entra ID, SharePoint Online, Exchange Online, Teams, Intune APIs) to administer, audit, or migrate.

| Script File Path | Description |
| :--- | :--- |
| **`Cloud_Scripts/Utilities/ConnectO365Services.ps1`** | Automates credentials retrieval, module installation, and remote sessions connection for 9 Microsoft 365 cloud services (Exchange, Teams, SPO, Graph, etc.). |
| **`Cloud_Scripts/Exchange_Management/ATP Implementation.ps1`** | Configures Advanced Threat Protection (ATP) policies (Safe Links, Safe Attachments) in Exchange Online. |
| **`Cloud_Scripts/Exchange_Management/Enable Mailbox Auditing Single Tenant.ps1`** | Connects to Exchange Online and enables auditing for all user mailboxes to track administrative and user actions. |
| **`Cloud_Scripts/Exchange_Management/Update Block Auto-FW.ps1`** | Configures cloud outbound spam filter policies to disable/block automatic external email forwarding organization-wide. |
| **`Cloud_Scripts/Exchange_Management/Update Disable Self-Service Purchase-All Customers.ps1`** | Uses the MSCommerce PowerShell module to disable self-service licensing purchases by end-users. |
| **`Cloud_Scripts/Exchange_Management/Update Hardening Exchange-New Tenant Onboarding.ps1`** | Hardens mail flow of newly onboarded tenants, implementing DKIM/DMARC configurations and disabling legacy transport protocols. |
| **`Cloud_Scripts/Exchange_Management/partner id.ps1`** | Associates Microsoft Partner Network (MPN) ID (PAL/DPOR) to the cloud Azure/O365 subscription for partner tracking. |
| **`Cloud_Scripts/Intune/Scripts/Backup-FullIntuneConfig.ps1`** | Backs up all Microsoft Intune device configurations, compliance policies, applications, and settings to local storage via Graph API. |
| **`Cloud_Scripts/Intune/Scripts/BackupImportCApolicies.ps1`** | Exports and imports Entra ID Conditional Access policies via MS Graph API. |
| **`Cloud_Scripts/Intune/Scripts/Connect-IntuneAutomat.ps1`** | Connects to the Microsoft Graph API using application registration credentials for Intune automation. |
| **`Cloud_Scripts/Intune/Scripts/Get-IntuneOffboardingToolv2.ps1`** | Automates clean removal of Intune MDM policies, registry keys, certificates, and profiles from offboarded tenants. |
| **`Cloud_Scripts/Intune/Scripts/Invoke-SRIntuneBackupComplianceNotificationMessageTemplates.ps1`** | Backs up Intune compliance notification templates (email headers, footers, localizations). |
| **`Cloud_Scripts/Intune/Scripts/Update-DeviceAutopilotRecord.ps1`** | Queries the Microsoft Graph API to update device Windows Autopilot assignment markers and group tags in bulk. |
| **`Cloud_Scripts/Intune/Scripts/Update-WindowsOSCompliancePolicy.ps1`** | Automates setting compliance rules for minimum required OS versions, patch levels, and security states on Windows devices in Intune. |
| **`Cloud_Scripts/M365_Assessment/DL_Members.ps1`** | Exports distribution lists and their corresponding group members from Exchange Online to CSV files. |
| **`Cloud_Scripts/M365_Assessment/ExportCAPolicies.ps1`** | Connects to Entra ID and dumps all Conditional Access policy details into JSON files for auditing. |
| **`Cloud_Scripts/M365_Assessment/Identity_devices_non_mobile.ps1`** | Audits and reports on non-mobile devices registered in Entra ID, tracking compliance and active sign-in metrics. |
| **`Cloud_Scripts/M365_Assessment/M365 assessment ALL.ps1`** | Master assessment orchestration script that queries Entra ID, Teams, and SharePoint to build an overall tenant maturity and compliance report. |
| **`Cloud_Scripts/M365_Assessment/Mailbox and Archive size.ps1`** | Audits mailboxes to export archive usage, storage quotas, and current consumption levels to CSV. |
| **`Cloud_Scripts/M365_Assessment/OneDrive report.ps1`** | Crawls SharePoint Online to export personal OneDrive storage limits, active folder usage, and external sharing flags. |
| **`Cloud_Scripts/M365_Assessment/Reporting_Teams-Telephony.ps1`** | Audits MS Teams Phone system configurations, active direct routing, and phone numbers. |
| **`Cloud_Scripts/M365_Assessment/SPO_stts.ps1`** | Fetches SharePoint Online site collections storage metrics and templates configuration. |
| **`Cloud_Scripts/M365_Assessment/Sec_improvements.ps1`** | Audit and remediation script for tenant security standards (SIEM, PIM, Modern Auth, spam notifications). |
| **`Cloud_Scripts/M365_Assessment/TeamsMailnickname.ps1`** | Audits Teams mail nicknames and unified group addresses. |
| **`Cloud_Scripts/M365_Assessment/Teams_Report.ps1`** | Crawls the tenant to generate a detailed report of all active Microsoft Teams, their owners, guest access flags, and privacy settings. |
| **`Cloud_Scripts/M365_Assessment/Tenant_reports.ps1`** | Performs global licensing, domain status, and administrator audits on the tenant. |
| **`Cloud_Scripts/M365_Assessment/reportM365.ps1`** | Connects to multiple M365 services to generate a massive, fully styled HTML and CSV administration report covering users, groups, licenses, and services. |
| **`Cloud_Scripts/M365_Assessment/update_modules_M365.ps1`** | Connects to the PowerShell Gallery to check, download, and install latest updates for M365 management modules. |
| **`Cloud_Scripts/M365_Assessment/Other_Assessment/AAA_Mailbox_sizes.ps1`** | Formats and groups user mailboxes by active size categories for licensing audits. |
| **`Cloud_Scripts/M365_Assessment/Other_Assessment/Mail_report.ps1`** | Multi-tenant Exchange report generating user transport status and inbox rules. |
| **`Cloud_Scripts/M365_Assessment/Other_Assessment/SPO_usage.ps1`** | Analyzes SharePoint storage growth trends and details active sites vs. stale sites. |
| **`Cloud_Scripts/M365_Assessment/Other_Assessment/Teams_assessment.ps1`** | Deep structural analysis of active Teams chat settings, guest invite settings, and policy permissions. |
| **`Cloud_Scripts/M365_Assessment/Other_Assessment/Teams_assessment_Global_Reader.ps1`** | Similar to Teams assessment, optimized to execute utilizing limited Global Reader read-only administrative roles. |
| **`Cloud_Scripts/M365_Assessment/Other_Assessment/Licensing/licensing_GRAPH.ps1`** | Interrogates MS Graph API to parse tenant service plans, subscription SKUs, and assigned license pools. |
| **`Cloud_Scripts/M365_Assessment/Other_Assessment/Licensing/Licensing_report.ps1`** | Pulls M365 licensing assignments in bulk to locate unassigned, expensive, or duplicate active subscription plans. |
| **`Cloud_Scripts/M365_Assessment/Other_Assessment/Licensing/O365UserLicenseReport.ps1`** | Formats a user-by-user cloud license configuration lookup table. |
| **`Cloud_Scripts/Migration/bittitan_statistics.ps1`** | Programmatically calls the BitTitan MigrationWiz API to generate migration error lists, mailbox statistics, and speed calculations. |
| **`Cloud_Scripts/SharePoint/Sharepoint_bulk_creation.ps1`** | Consumes a CSV template to bulk create Microsoft Teams and provision their corresponding SharePoint Online backend sites. |

---

### 🏢 On-Premises Scripts (`OnPremises_Scripts/`)
These scripts execute on local systems, interact with Active Directory Domain Services, configure physical registry keys, map network shares, manage local policies, or audit local application environments.

| Script File Path | Description |
| :--- | :--- |
| **`OnPremises_Scripts/Exchange_Management/Mailboxtypes.ps1`** | Imports samAccountNames from a CSV file to enable Exchange Remote Mailboxes (Hybrid Exchange setups connecting local AD objects to Exchange Online). |
| **`OnPremises_Scripts/Exchange_Management/Exchange 2019 or SE Assestment/HealthChecker.ps1`** | Checks the target Exchange 2019 or SE server for configuration recommendations and potential issues from the Microsoft Exchange Product Group. |
| **`OnPremises_Scripts/Exchange_Management/Exchange 2019 or SE Assestment/Mailbox_assestment.ps1`** | Generates detailed statistics reports (mailbox sizes, recovery sizes, folders stats, and quotas) for all or selected Exchange mailboxes. |
| **`OnPremises_Scripts/Intune/EndpointScripts/DriveMapping.ps1`** | Runs on client computers (distributed via Intune) to map physical on-premises network drives and share locations based on user AD groups. |
| **`OnPremises_Scripts/Intune/EndpointScripts/DriveMappingJson.ps1`** | A modernized drive mapper that consumes a JSON file outlining server UNC paths to dynamically map on-premises drives for clients. |
| **`OnPremises_Scripts/Intune/EndpointScripts/PrinterMapping.ps1`** | Dynamically maps active on-premises network printers and setups TCP/IP printing ports on the local client machine. |
| **`OnPremises_Scripts/Intune/EndpointScripts/PrinterMappingJson.ps1`** | Configures local client on-prem printers dynamically using input configuration from JSON arrays. |
| **`OnPremises_Scripts/Intune/HAADJCompuerRename-app.ps1`** | Local client utility distributed as an app to rename on-prem computer names that are Hybrid Azure AD Joined (HAADJ), matching the cloud naming convention. |
| **`OnPremises_Scripts/Intune/HybridCompuerRename-detect.ps1`** | Detection script checking whether a local Hybrid Azure AD Joined device's on-premises computer name complies with the corporate naming policy. |
| **`OnPremises_Scripts/Intune/HybridCompuerRename-remediate.ps1`** | Remediation script that runs on the local Windows machine to rename the computer account in local Active Directory and trigger system reboots. |
| **`OnPremises_Scripts/Intune/TurnOffWindowsCopilot-detect.ps1`** | Detects whether Windows Copilot has been disabled in the local client registry or Group Policies on-premises. |
| **`OnPremises_Scripts/Intune/TurnOffWindowsCopilot-remediate.ps1`** | Remediation script setting local machine registry keys to completely turn off Windows Copilot on local endpoints. |
| **`OnPremises_Scripts/Intune/Get-UserRights.ps1`** | Audits local machine User Rights Assignment policies (e.g., Log on as a service, shut down system) in Windows Local Security Policy. |
| **`OnPremises_Scripts/Intune/Set-UserRights.ps1`** | Modifies and secures Windows local User Rights Assignments on on-premises systems and servers. |
| **`OnPremises_Scripts/Intune/Register-AutopilotDevice.ps1`** | Local client script to gather hardware hash (CSV) and register the physical machine directly into Autopilot database. |
| **`OnPremises_Scripts/Intune/Reset-DeviceForAutopilot.ps1`** | Formats, cleans, and resets local Windows client configurations preparing the physical workstation for Autopilot enrollments. |
| **`OnPremises_Scripts/Intune/OD-MountTimer-detect.ps1`** | Detection script checking if OneDrive local client auto-mount schedules are set in local task scheduler. |
| **`OnPremises_Scripts/Intune/OD-MountTimer-remediate.ps1`** | Creates local Task Scheduler items to force OneDrive folder mapping for user profiles. |
| **`OnPremises_Scripts/Intune/Combine-CsvFiles.ps1`** | Simple file utility that merges multiple CSV files in a local folder into a single compiled file. |
| **`OnPremises_Scripts/Intune/InstallPSModules.ps1`** | Script running locally on client machines to install standard PowerShell administration modules. |
| **`OnPremises_Scripts/M365_Assessment/citrix_assessment.ps1`** | Uses local Citrix snaps (Get-BrokerApplication) to compile published applications and desktops lists from on-premises Citrix XenApp/XenDesktop controller farms. |
| **`OnPremises_Scripts/Utilities/proxy.ps1`** | Configures the default proxy credentials and TLS 1.2 system networking settings in the local operating system. |
| **`OnPremises_Scripts/Utilities/m365cachecleaning.ps1`** | Interactive terminal menu that clears caches for Microsoft Teams, OneDrive, Outlook, Word, Excel, Edge, and OneNote on the local workstation. |

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
