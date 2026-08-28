#!/usr/bin/env python3
"""Integrate O365scripts upstream into Microsoft-Workspace naming and folder layout."""

from __future__ import annotations

import re
import shutil
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
UPSTREAM = Path("/tmp/O365scripts-upstream")
UPSTREAM_BASE = "https://github.com/O365scripts/O365scripts/blob/master"

# (upstream_relative_path, dest_relative_path, script_id, title, description)
INTEGRATIONS: list[tuple[str, str, str, str, str]] = [
    # Exchange Online (EXO-008+)
    ("Exchange Online/EXO - Distribution Group Management.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-008_Distribution-Group-Management.ps1",
     "EXO-008", "Distribution Group Management",
     "Full distribution group membership overview and CSV export."),
    ("Exchange Online/EXO - Distribution Group Member Management.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-009_Distribution-Group-Member-Management.ps1",
     "EXO-009", "Distribution Group Member Management",
     "Add, remove, and manage distribution group members."),
    ("Exchange Online/EXO - Distribution Groups.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-010_Distribution-Groups.ps1",
     "EXO-010", "Distribution Groups",
     "Create, modify, and remove distribution groups."),
    ("Exchange Online/EXO - Mailbox Alias Management.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-011_Mailbox-Alias-Management.ps1",
     "EXO-011", "Mailbox Alias Management",
     "Manage SMTP aliases on Exchange Online mailboxes."),
    ("Exchange Online/EXO - Mailbox Audit Flags Management.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-012_Mailbox-Audit-Flags-Management.ps1",
     "EXO-012", "Mailbox Audit Flags Management",
     "Configure mailbox audit logging flags per mailbox."),
    ("Exchange Online/EXO - Mailbox Client Access Settings Management.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-013_Mailbox-Client-Access-Settings-Management.ps1",
     "EXO-013", "Mailbox Client Access Settings Management",
     "Manage CAS mailbox settings (MAPI, OWA, ActiveSync, etc.)."),
    ("Exchange Online/EXO - Mailbox Permission Management.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-014_Mailbox-Permission-Management.ps1",
     "EXO-014", "Mailbox Permission Management",
     "Grant and revoke mailbox permissions (FullAccess, SendAs, SendOnBehalf)."),
    ("Exchange Online/EXO - Mailbox Quota Management.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-015_Mailbox-Quota-Management.ps1",
     "EXO-015", "Mailbox Quota Management",
     "Set and report mailbox storage quotas and warnings."),
    ("Exchange Online/EXO - Mailbox Restore Request.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-016_Mailbox-Restore-Request.ps1",
     "EXO-016", "Mailbox Restore Request",
     "Create and monitor mailbox restore requests."),
    ("Exchange Online/EXO - Mailbox Retain Deleted Items Management.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-017_Mailbox-Retain-Deleted-Items-Management.ps1",
     "EXO-017", "Mailbox Retain Deleted Items Management",
     "Configure deleted item retention per mailbox."),
    ("Exchange Online/EXO - Message Trace External Recipients.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-018_Message-Trace-External-Recipients.ps1",
     "EXO-018", "Message Trace External Recipients",
     "Trace messages sent to external recipients."),
    ("Exchange Online/EXO - Mobile Device Management.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-019_Mobile-Device-Management.ps1",
     "EXO-019", "Mobile Device Management",
     "Manage mobile device partnerships and wipe actions."),
    ("Exchange Online/EXO - Office Message Encryption.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-020_Office-Message-Encryption.ps1",
     "EXO-020", "Office Message Encryption",
     "Configure and manage OME encryption policies."),
    ("Exchange Online/EXO - Organization Management.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-021_Organization-Management.ps1",
     "EXO-021", "Organization Management",
     "View and modify Exchange Online organization settings."),
    ("Exchange Online/EXO - RBAC.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-022_RBAC-Management.ps1",
     "EXO-022", "RBAC Management",
     "Manage Exchange Online role-based access control."),
    ("Exchange Online/EXO - Tenant Hydration.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-023_Tenant-Hydration.ps1",
     "EXO-023", "Tenant Hydration",
     "Check and trigger Exchange Online tenant hydration status."),
    ("Exchange Online/EXO - Trusted or Blocked Senders Mailbox Management.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-024_Trusted-Blocked-Senders-Management.ps1",
     "EXO-024", "Trusted or Blocked Senders Management",
     "Manage trusted and blocked sender lists on mailboxes."),
    ("Exchange Online/EXO - Unified Groups Hidden from GAL or Outlook.ps1",
     "Cloud_Scripts/Exchange_Management/EXO-025_Unified-Groups-Hidden-From-GAL.ps1",
     "EXO-025", "Unified Groups Hidden from GAL",
     "Show or hide Microsoft 365 Groups from GAL and Outlook."),
    # Teams (TEA-007+)
    ("Microsoft Teams/Teams - Application Cache Clear.ps1",
     "Cloud_Scripts/Teams/TEA-007_Application-Cache-Clear.ps1",
     "TEA-007", "Application Cache Clear",
     "Clear Microsoft Teams application cache on endpoints."),
    ("Microsoft Teams/Teams - Audio Conferencing User Management.ps1",
     "Cloud_Scripts/Teams/TEA-008_Audio-Conferencing-User-Management.ps1",
     "TEA-008", "Audio Conferencing User Management",
     "Assign and manage audio conferencing licenses and settings."),
    ("Microsoft Teams/Teams - Channel Management.ps1",
     "Cloud_Scripts/Teams/TEA-009_Channel-Management.ps1",
     "TEA-009", "Channel Management",
     "Add, remove, and list Teams channel members."),
    ("Microsoft Teams/Teams - Cloud Recording Management.ps1",
     "Cloud_Scripts/Teams/TEA-010_Cloud-Recording-Management.ps1",
     "TEA-010", "Cloud Recording Management",
     "Manage Teams cloud meeting recording policies."),
    ("Microsoft Teams/Teams - Direct Routing Tenant Overview.ps1",
     "Cloud_Scripts/Teams/TEA-011_Direct-Routing-Tenant-Overview.ps1",
     "TEA-011", "Direct Routing Tenant Overview",
     "Export Direct Routing SBC and voice route configuration."),
    ("Microsoft Teams/Teams - Direct Routing User Overview.ps1",
     "Cloud_Scripts/Teams/TEA-012_Direct-Routing-User-Overview.ps1",
     "TEA-012", "Direct Routing User Overview",
     "Report users with Direct Routing voice configuration."),
    ("Microsoft Teams/Teams - Enterprise Voice.ps1",
     "Cloud_Scripts/Teams/TEA-013_Enterprise-Voice.ps1",
     "TEA-013", "Enterprise Voice",
     "Enterprise Voice policy and user assignment management."),
    ("Microsoft Teams/Teams - Resource Account Association.ps1",
     "Cloud_Scripts/Teams/TEA-014_Resource-Account-Association.ps1",
     "TEA-014", "Resource Account Association",
     "Associate resource accounts with Teams applications."),
    ("Microsoft Teams/Teams - Resource Account Management.ps1",
     "Cloud_Scripts/Teams/TEA-015_Resource-Account-Management.ps1",
     "TEA-015", "Resource Account Management",
     "Create and manage Teams resource accounts."),
    ("Microsoft Teams/Teams - Resource Account Troubleshooting.ps1",
     "Cloud_Scripts/Teams/TEA-016_Resource-Account-Troubleshooting.ps1",
     "TEA-016", "Resource Account Troubleshooting",
     "Diagnose Teams resource account and CQ/AA issues."),
    ("Microsoft Teams/Teams - Team Membership Copy.ps1",
     "Cloud_Scripts/Teams/TEA-017_Team-Membership-Copy.ps1",
     "TEA-017", "Team Membership Copy",
     "Copy team membership from one team to another."),
    ("Microsoft Teams/Teams - Team Overview.ps1",
     "Cloud_Scripts/Teams/TEA-018_Team-Overview.ps1",
     "TEA-018", "Team Overview",
     "Export Teams overview including owners, members, and settings."),
    ("Microsoft Teams/Teams - Team Visibility Management.ps1",
     "Cloud_Scripts/Teams/TEA-019_Team-Visibility-Management.ps1",
     "TEA-019", "Team Visibility Management",
     "Change Teams visibility (public/private) in bulk."),
    ("Microsoft Teams/Teams - Telephone Number Overview.ps1",
     "Cloud_Scripts/Teams/TEA-020_Telephone-Number-Overview.ps1",
     "TEA-020", "Telephone Number Overview",
     "Inventory assigned and unassigned telephone numbers."),
    ("Microsoft Teams/Teams - Telephone Number Portability Test.ps1",
     "Cloud_Scripts/Teams/TEA-021_Telephone-Number-Portability-Test.ps1",
     "TEA-021", "Telephone Number Portability Test",
     "Run number portability validation tests."),
    ("Microsoft Teams/Teams - User Phone Number Management.ps1",
     "Cloud_Scripts/Teams/TEA-022_User-Phone-Number-Management.ps1",
     "TEA-022", "User Phone Number Management",
     "Assign and unassign phone numbers to Teams users."),
    ("Microsoft Teams/Teams - Voice Overview.ps1",
     "Cloud_Scripts/Teams/TEA-023_Voice-Overview.ps1",
     "TEA-023", "Voice Overview",
     "Full Teams voice configuration tenant overview."),
    ("Microsoft Teams/TeamsTelephoneNumberSearchAndAcquireLegacy.ps1",
     "Cloud_Scripts/Teams/TEA-024_Telephone-Number-Search-Acquire-Legacy.ps1",
     "TEA-024", "Telephone Number Search and Acquire (Legacy)",
     "Search and acquire telephone numbers (legacy cmdlet flow)."),
    ("Microsoft Teams/TeamsUpgradeStatusManagement.ps1",
     "Cloud_Scripts/Teams/TEA-025_Upgrade-Status-Management.ps1",
     "TEA-025", "Upgrade Status Management",
     "Manage Skype-to-Teams upgrade status for users."),
    ("Microsoft Teams/TeamsVoiceUserOverview.ps1",
     "Cloud_Scripts/Teams/TEA-026_Voice-User-Overview.ps1",
     "TEA-026", "Voice User Overview",
     "Export per-user Teams voice settings and policies."),
    # SharePoint (SPO-011+)
    ("SharePoint Online/OneDrive Client Management.ps1",
     "Cloud_Scripts/SharePoint/SPO-011_OneDrive-Client-Management.ps1",
     "SPO-011", "OneDrive Client Management",
     "Manage OneDrive sync client settings and policies."),
    ("SharePoint Online/SPO - Site Owner Management.ps1",
     "Cloud_Scripts/SharePoint/SPO-012_Site-Owner-Management.ps1",
     "SPO-012", "Site Owner Management",
     "Add and remove SharePoint site collection owners."),
    ("SharePoint Online/SPO - Site Quota.ps1",
     "Cloud_Scripts/SharePoint/SPO-013_Site-Quota-Management.ps1",
     "SPO-013", "Site Quota Management",
     "View and set SharePoint site storage quotas."),
    ("SharePoint Online/SPO - Site Sharing Capability Management.ps1",
     "Cloud_Scripts/SharePoint/SPO-014_Site-Sharing-Capability-Management.ps1",
     "SPO-014", "Site Sharing Capability Management",
     "Manage external sharing capability per site."),
    ("SharePoint Online/PNP/SPO-PNP - Document Library Permission Inheritance Management.ps1",
     "Cloud_Scripts/SharePoint/SPO-015_Document-Library-Permission-Inheritance.ps1",
     "SPO-015", "Document Library Permission Inheritance",
     "Break, restore, and audit library permission inheritance via PnP."),
    ("SharePoint Online/PNP/SPO-PNP - Recycle Bin Management.ps1",
     "Cloud_Scripts/SharePoint/SPO-016_Recycle-Bin-Management.ps1",
     "SPO-016", "Recycle Bin Management",
     "Manage site and second-stage recycle bins via PnP."),
    # Entra ID
    ("Azure AD/ADSyncCycleManagement.ps1",
     "Cloud_Scripts/Entra_ID/ENT-001_ADSync-Cycle-Management.ps1",
     "ENT-001", "ADSync Cycle Management",
     "Start full/delta sync and configure Azure AD Connect scheduler."),
    ("Azure AD/AzureDeviceManagement.ps1",
     "Cloud_Scripts/Entra_ID/ENT-002_Azure-Device-Management.ps1",
     "ENT-002", "Azure Device Management",
     "Manage Entra ID registered and joined devices."),
    ("Microsoft Online/MSOL - Deleted User Management.ps1",
     "Cloud_Scripts/Entra_ID/ENT-003_MSOL-Deleted-User-Management.ps1",
     "ENT-003", "MSOL Deleted User Management",
     "List, restore, and permanently delete soft-deleted users."),
    # Security & Compliance
    ("Azure Information Protection/AIP - Activation.ps1",
     "Cloud_Scripts/Security_and_Compliance/SEC-001_AIP-Activation.ps1",
     "SEC-001", "AIP Activation",
     "Activate Azure Information Protection unified labeling."),
    ("Security & Compliance/S&C - Search and Delete.ps1",
     "Cloud_Scripts/Security_and_Compliance/SCC-001_Compliance-Search-and-Delete.ps1",
     "SCC-001", "Compliance Search and Delete",
     "Create compliance searches and purge matching content."),
    # Utilities / Tools
    ("Tools/Connect-M365.ps1",
     "Cloud_Scripts/Utilities/Connection/UTL-025_Connect-M365.ps1",
     "UTL-025", "Connect M365",
     "Connect to common M365 services (O365scripts variant)."),
    ("Tools/Connect-M365NoMFA.ps1",
     "Cloud_Scripts/Utilities/Connection/UTL-026_Connect-M365-NoMFA.ps1",
     "UTL-026", "Connect M365 No MFA",
     "Connect to M365 services without MFA prompt."),
    ("Tools/Get-M365DomainDnsOverview.ps1",
     "Cloud_Scripts/Utilities/UTL-027_Get-M365-Domain-Dns-Overview.ps1",
     "UTL-027", "M365 Domain DNS Overview",
     "Export DNS records required for M365 domain validation."),
    ("Tools/Get-M365ModuleOverview.ps1",
     "Cloud_Scripts/Utilities/UTL-028_Get-M365-Module-Overview.ps1",
     "UTL-028", "M365 Module Overview",
     "List installed M365 PowerShell modules and versions."),
    ("Tools/Get-M365TeamsUpgradeStatus.ps1",
     "Cloud_Scripts/Utilities/UTL-029_Get-M365-Teams-Upgrade-Status.ps1",
     "UTL-029", "M365 Teams Upgrade Status",
     "Report Skype-to-Teams upgrade status for users."),
    ("Tools/Get-M365UserOverview.ps1",
     "Cloud_Scripts/Utilities/UTL-030_Get-M365-User-Overview.ps1",
     "UTL-030", "M365 User Overview",
     "Export comprehensive user account overview."),
    ("Tools/Invoke-M365CheckSystemRequirements.ps1",
     "Cloud_Scripts/Utilities/UTL-031_Invoke-M365-Check-System-Requirements.ps1",
     "UTL-031", "M365 System Requirements Check",
     "Validate PowerShell and .NET prerequisites for M365 scripts."),
    ("Tools/M365 Bulk Domain Overview.ps1",
     "Cloud_Scripts/Utilities/UTL-032_M365-Bulk-Domain-Overview.ps1",
     "UTL-032", "M365 Bulk Domain Overview",
     "Bulk domain status overview across tenants."),
    ("Tools/M365 DNS Overview.ps1",
     "Cloud_Scripts/Utilities/UTL-033_M365-DNS-Overview.ps1",
     "UTL-033", "M365 DNS Overview",
     "Compare tenant DNS records against Microsoft requirements."),
    ("Tools/O365 - System Requirements.ps1",
     "Cloud_Scripts/Utilities/UTL-034_O365-System-Requirements.ps1",
     "UTL-034", "O365 System Requirements",
     "Check Windows PowerShell and WMF prerequisites."),
    ("Tools/Search-EmailAddress.ps1",
     "Cloud_Scripts/Utilities/UTL-035_Search-Email-Address.ps1",
     "UTL-035", "Search Email Address",
     "Search for an email address across EXO recipient types."),
]

# Already integrated upstream scripts (reference only)
ALREADY_INTEGRATED = [
    ("Connection/O365ConnectAll.ps1", "UTL-009_Connect-All.ps1", "Cloud_Scripts/Utilities/Connection/"),
    ("Connection/O365ConnectAzureActiveDirectory.ps1", "UTL-010_Connect-AzureAD.ps1", "Cloud_Scripts/Utilities/Connection/"),
    ("Connection/O365ConnectCommerce.ps1", "UTL-011_Connect-Commerce.ps1", "Cloud_Scripts/Utilities/Connection/"),
    ("Connection/O365ConnectExchangeOnline.ps1", "UTL-012_Connect-Exchange-Online.ps1", "Cloud_Scripts/Utilities/Connection/"),
    ("Connection/O365ConnectExchangeOnlineBasicDeprecated.ps1", "UTL-013_Connect-Exchange-Online-Basic-Deprecated.ps1", "Cloud_Scripts/Utilities/Connection/"),
    ("Connection/O365ConnectMicrosoftOnlineMSOL.ps1", "UTL-014_Connect-MSOnline.ps1", "Cloud_Scripts/Utilities/Connection/"),
    ("Connection/O365ConnectMicrosoftTeams.ps1", "UTL-015_Connect-Teams.ps1", "Cloud_Scripts/Utilities/Connection/"),
    ("Connection/O365ConnectSecurityCompliance.ps1", "UTL-016_Connect-Security-Compliance.ps1", "Cloud_Scripts/Utilities/Connection/"),
    ("Connection/O365ConnectSharePointOnline.ps1", "UTL-017_Connect-SharePoint-Online.ps1", "Cloud_Scripts/Utilities/Connection/"),
    ("Connection/O365ConnectSkypeForBusinessOnlineDeprecated.ps1", "UTL-018_Connect-Skype-Online-Deprecated.ps1", "Cloud_Scripts/Utilities/Connection/"),
    ("Connection/O365ConnectSPOPNP.ps1", "UTL-019_Connect-SharePoint-PnP.ps1", "Cloud_Scripts/Utilities/Connection/"),
    ("Common Functions/Get-RandomAlphaNumString.ps1", "UTL-020_Get-RandomAlphaNumString.ps1", "Cloud_Scripts/Utilities/Common/"),
    ("Common Functions/Get-Timestamp.ps1", "UTL-021_Get-Timestamp.ps1", "Cloud_Scripts/Utilities/Common/"),
    ("Templates/New.ps1", "UTL-022_New-Script-Template.ps1", "Cloud_Scripts/Utilities/Templates/"),
    ("Templates/NewFunction.ps1", "UTL-023_New-Function-Template.ps1", "Cloud_Scripts/Utilities/Templates/"),
    ("Office Apps/Office Apps Management.ps1", "UTL-024_Office-Apps-Management.ps1", "Cloud_Scripts/Office_Apps/"),
    ("Exchange Online/ExchangeOnlineMailboxConversion.ps1", "EXO-007_Exchange-Mailbox-Conversion.ps1", "Cloud_Scripts/Exchange_Management/"),
    ("Microsoft Graph/MS Graph - Licensing Overview.ps1", "M365-019_MS-Graph-Licensing-Overview.ps1", "Cloud_Scripts/M365_Assessment/"),
    ("Tools/Install-M365Module.ps1", "UTL-005_Install-PSModules.ps1", "OnPremises_Scripts/Utilities/"),
]


def upstream_url(rel: str) -> str:
    return f"{UPSTREAM_BASE}/{rel.replace(' ', '%20')}"


def strip_existing_help(content: str) -> str:
    content = content.lstrip("\ufeff")
    if content.startswith("<#"):
        end = content.find("#>", 2)
        if end != -1:
            return content[end + 2 :].lstrip("\r\n")
    return content


def build_header(script_id: str, title: str, description: str, upstream_rel: str, dest_name: str) -> str:
    return f"""<#
.SYNOPSIS
    {script_id} | {title}.

.DESCRIPTION
    {description}

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect ({script_id} classification)

.VERSION
    1.0

.LINK
    {upstream_url(upstream_rel)}

.NOTES
    Name: {dest_name}
    Integrated from O365scripts upstream repository.
#>

"""


def integrate() -> list[tuple[str, str, str, str]]:
    integrated: list[tuple[str, str, str, str]] = []
    for upstream_rel, dest_rel, script_id, title, description in INTEGRATIONS:
        src = UPSTREAM / upstream_rel
        dest = REPO / dest_rel
        if not src.exists():
            raise FileNotFoundError(f"Missing upstream file: {src}")
        dest.parent.mkdir(parents=True, exist_ok=True)
        body = strip_existing_help(src.read_text(encoding="utf-8", errors="replace"))
        header = build_header(script_id, title, description, upstream_rel, dest.name)
        dest.write_text(header + body, encoding="utf-8")
        integrated.append((script_id, dest_rel, title, description))
        print(f"  + {dest_rel}")
    return integrated


def write_map(integrated: list[tuple[str, str, str, str]]) -> None:
    lines = [
        "# O365scripts Integration Map",
        "",
        "> Source: [O365scripts/O365scripts](https://github.com/O365scripts/O365scripts)",
        "> License: See upstream repository. Integrated scripts retain original logic with standardized naming.",
        "",
        "## Newly Integrated Scripts",
        "",
        "| Workspace ID | Workspace Path | Upstream Original | Description |",
        "|--------------|----------------|-------------------|-------------|",
    ]
    for upstream_rel, dest_rel, script_id, title, description in INTEGRATIONS:
        lines.append(
            f"| {script_id} | `{dest_rel}` | `{upstream_rel}` | {description} |"
        )
    lines.extend([
        "",
        "## Previously Integrated (Upstream Equivalents)",
        "",
        "| Workspace Script | Upstream Original |",
        "|------------------|-------------------|",
    ])
    for upstream_rel, workspace_name, folder in ALREADY_INTEGRATED:
        lines.append(f"| `{folder}{workspace_name}` | `{upstream_rel}` |")
    (REPO / "O365SCRIPTS_MAP.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    print("Integrating O365scripts...")
    result = integrate()
    write_map(result)
    print(f"\nDone: {len(result)} scripts integrated.")
    print(f"Map written to O365SCRIPTS_MAP.md")
