# Microsoft Workspace – Advanced M365 Administration

Centralized repository of PowerShell scripts, templates, and documentation for advanced administrators of **Microsoft 365**, **Entra ID**, **Exchange Online**, **Teams**, **SharePoint**, **Intune**, and hybrid environments.

---

## Repository Structure

```
Microsoft-Workspace/
├── Cloud_Scripts/              # Cloud-native administration
│   ├── Azure/                  # Azure monitoring and resources
│   ├── Entra_ID/               # Identity, CA, devices
│   ├── Exchange_Management/    # EXO, Defender, mail-flow
│   ├── Intune/                 # Endpoint Manager, Autopilot, Win32
│   ├── M365_Assessment/        # Cross-service reports (licensing, SPO, security)
│   ├── Migration/              # Migration tools (BitTitan, etc.)
│   ├── Office_Apps/            # Click-to-Run and local activation
│   ├── Security_and_Compliance/ # Purview / Compliance Center (extensible)
│   ├── SharePoint/             # SPO, PnP migrations, provisioning
│   ├── Teams/                  # Inventory, retention, telephony
│   └── Utilities/              # Connectivity, modules, templates
│       ├── Connection/         # Per-service connectors (UTL-009 to UTL-019)
│       ├── Common/             # Helper functions (UTL-020, UTL-021)
│       └── Templates/          # Script/function templates (UTL-022, UTL-023)
├── OnPremises_Scripts/         # AD, on-prem Exchange, local endpoints
├── Governance_and_Policies/    # Governance frameworks and policies
├── Reports/                    # Generated CSV/HTML output (gitignored)
├── Templates/                  # CA templates, team CSVs, etc.
├── SCRIPT_INDEX.md             # Complete script catalog
└── README.md
```

---

## Naming Convention

```
<PREFIX>-<NNN>_<ShortDescription>.ps1
```

| Prefix | Technology / Product |
|--------|----------------------|
| `EXO` | Exchange Online / Defender for Office 365 |
| `SPO` | SharePoint Online / PnP |
| `TEA` | Microsoft Teams |
| `M365` | Cross-service assessment / Microsoft Graph |
| `INT` | Microsoft Intune / Autopilot |
| `UTL` | Utilities (connectivity, modules, helpers) |
| `OPR` | On-Premises (Citrix, Exchange Server) |
| `MIG` | Migration |

---

## Quick Start

```powershell
# 1. Execution policy (current session)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# 2. Install M365 modules
.\OnPremises_Scripts\Utilities\UTL-005_Install-PSModules.ps1

# 3. Connect to all services
.\Cloud_Scripts\Utilities\UTL-001_Connect-O365Services.ps1

# 4. Browse the catalog
Get-Content .\SCRIPT_INDEX.md
```

---

## Recommended Workflows

See the full map in **[SCRIPT_INDEX.md](SCRIPT_INDEX.md#workflow-map-recommended-execution-order)**.

| Phase | Key Scripts |
|-------|-------------|
| **Assessment** | `M365-001` → `M365-014`, `TEA-001` → `TEA-004`, `SPO-001` |
| **Hardening** | `EXO-005` → `EXO-001` → `EXO-004` |
| **SPO Migration** | `SPO-001` → `SPO-003` → `SPO-005` → `SPO-006` |
| **Intune** | `INT-001` → `INT-002` → `INT-005` |

---

## Code Standards

1. **English help headers** using comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`)
2. **79-character region wrappers** for IDE navigation (`#region ── Parameters ──`)
3. **AST validation** before commit: `[System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errs)`

---

## Security

Do not commit credentials, certificates, or customer data. Use certificate-based authentication (CBA) or MFA as documented in `UTL-001_Connect-O365Services.ps1`.

---

**Maintainer:** Josep Canas – M365 Solutions Architect
