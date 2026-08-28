# SharePoint Online – Migration Scripts (PnP Modern)

PowerShell scripts for M365 solution architects, built on **PnP.PowerShell** (v2.x+).  
They cover the full migration lifecycle: from pre-migration analysis to post-migration validation.

---

## Prerequisites

```powershell
# Install the modern PnP module
Install-Module PnP.PowerShell -Force -AllowClobber

# Verify version
Get-Module PnP.PowerShell -ListAvailable | Select-Object Name, Version
```

### Recommended Authentication (App-Only with Certificate)

```powershell
# 1. Register application in Entra ID with PnP
Register-PnPEntraIDApp `
    -ApplicationName "PnP-Migration-App" `
    -Tenant "contoso.onmicrosoft.com" `
    -OutPath "C:\Certs" `
    -CertificatePassword (ConvertTo-SecureString "MyPass!" -AsPlainText -Force) `
    -Scopes "Sites.FullControl.All","User.Read.All","Group.ReadWrite.All"
```

> **Minimum required permissions** (Graph + SharePoint):  
> `Sites.FullControl.All` · `User.Read.All` · `Group.ReadWrite.All` · `TermStore.ReadWrite.All`

---

## Included Scripts

| # | Script | Purpose | Type |
|---|--------|---------|------|
| 01 | `SPO-001_PreMigration-Assessment.ps1` | Full pre-migration inventory | Analysis |
| 02 | `SPO-002_SiteMigration-ClassicToModern.ps1` | Classic → modern migration | Migration |
| 03 | `SPO-003_TenantToTenant-Migration.ps1` | Tenant-to-Tenant (T2T) migration | Migration |
| 04 | `SPO-004_HubSpoke-Provisioning.ps1` | Full Hub-Spoke architecture | Provisioning |
| 05 | `SPO-005_PostMigration-Validation.ps1` | Post-migration validation and remediation | Validation |
| 06 | `SPO-006_Permissions-Management.ps1` | Bulk permission management | Governance |
| 07 | `SPO-007_SiteDesigns-Management.ps1` | Site Designs and Site Scripts | Standardization |

---

## Recommended Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                    M365 MIGRATION LIFECYCLE                 │
└─────────────────────────────────────────────────────────────┘

  [01] Assessment      →  Know what you have
       ↓
  [06] Permissions     →  Permission audit (Audit mode)
       ↓
  [07] Site Designs    →  Standardize destination templates (Create)
       ↓
  [04] Hub-Spoke       →  Build destination architecture
       ↓
  [02] Classic→Modern  →  Migrate classic / on-prem sites
    or
  [03] T2T Migration   →  Migrate between tenants
       ↓
  [06] Permissions     →  Remediate permissions (RemoveExternal, ReplaceGroup)
       ↓
  [05] Validation      →  Validate and auto-remediate
       ↓
  [07] Site Designs    →  Apply designs to migrated sites (ApplyToSites)
```

---

## Quick Usage by Script

### 01 – Assessment
```powershell
.\SPO-001_PreMigration-Assessment.ps1 `
    -TenantAdminUrl "https://contoso-admin.sharepoint.com" `
    -ClientId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
    -Thumbprint "AABB..." `
    -TenantId "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" `
    -OutputPath "C:\Reports\Assessment"
```

### 02 – Classic to Modern
```powershell
.\SPO-002_SiteMigration-ClassicToModern.ps1 `
    -SourceUrl "https://contoso.sharepoint.com/sites/Old" `
    -DestinationUrl "https://contoso.sharepoint.com/sites/New" `
    -ClientId "xxxx" -Thumbprint "AABB" -TenantId "yyyy" `
    -MigrateContent       # Includes files
```

### 03 – Tenant to Tenant
```powershell
.\SPO-003_TenantToTenant-Migration.ps1 `
    -SourceTenantAdminUrl "https://source-admin.sharepoint.com" `
    -DestTenantAdminUrl   "https://dest-admin.sharepoint.com" `
    -SourceSiteUrl "https://source.sharepoint.com/sites/HR" `
    -DestSiteUrl   "https://dest.sharepoint.com/sites/HR" `
    -SourceClientId "src-id" -SourceThumbprint "SRC..." -SourceTenantId "src-tid" `
    -DestClientId   "dst-id" -DestThumbprint   "DST..." -DestTenantId   "dst-tid" `
    -UserMappingCsv "C:\Migration\UserMapping.csv"
```
**User mapping CSV format:**
```csv
SourceUPN,DestinationUPN
john.doe@source.com,john.doe@dest.com
jane.smith@source.com,jane.smith@dest.com
```

### 04 – Hub-Spoke
```powershell
$spokes = @(
    @{ Title='IT Department'; Alias='it-dept'; Template='TeamSite'; PnPTemplate='C:\IT.xml' },
    @{ Title='HR Portal'; Alias='hr-portal'; Template='CommunicationSite'; PnPTemplate='C:\HR.xml' }
)
.\SPO-004_HubSpoke-Provisioning.ps1 `
    -TenantAdminUrl "https://contoso-admin.sharepoint.com" `
    -ClientId "xxxx" -Thumbprint "AABB" -TenantId "yyyy" `
    -HubTitle "Corporate Intranet" -HubAlias "corporate-intranet" `
    -SpokesDefinition $spokes `
    -HubTemplatePath "C:\Hub.xml"
```

### 05 – Post-Migration Validation
```powershell
.\SPO-005_PostMigration-Validation.ps1 `
    -SourceUrl "https://contoso.sharepoint.com/sites/Old" `
    -DestUrl   "https://contoso.sharepoint.com/sites/New" `
    -ClientId "xxxx" -Thumbprint "AABB" -TenantId "yyyy" `
    -AutoRemediate    # Auto-fix common issues
```

### 06 – Permission Management
```powershell
# Audit
.\SPO-006_Permissions-Management.ps1 -SiteUrl "..." -Mode Audit ...

# Remove external users
.\SPO-006_Permissions-Management.ps1 -SiteUrl "..." -Mode RemoveExternal ...

# Replace security group (useful in T2T)
.\SPO-006_Permissions-Management.ps1 -SiteUrl "..." -Mode ReplaceGroup `
    -OldGroupName "Source-Owners" -NewGroupName "Dest-Owners" ...
```

### 07 – Site Designs
```powershell
# Create design from JSON
.\SPO-007_SiteDesigns-Management.ps1 -Mode Create `
    -SiteDesignName "Departmental Template" `
    -SiteScriptJsonPath "C:\script.json" -WebTemplate "64" ...

# Apply design to multiple sites
.\SPO-007_SiteDesigns-Management.ps1 -Mode ApplyToSites `
    -SiteDesignName "Departmental Template" `
    -TargetSiteUrls @("https://contoso.sharepoint.com/sites/IT","...") ...

# Export full catalog
.\SPO-007_SiteDesigns-Management.ps1 -Mode ExportAll ...
```

---

## Architect Considerations

| Aspect | Recommendation |
|--------|----------------|
| **Throttling** | Use `-PageSize 500` and add `Start-Sleep -Seconds 1` in large loops |
| **Versions** | PnP.PowerShell v2.x is incompatible with the legacy SharePoint PnPOnlineCommands module |
| **Certificates** | Use 2048-bit certificates minimum; rotate every 6 months |
| **T2T** | Microsoft SPMT (SharePoint Migration Tool) complements bulk content migration |
| **Broken permissions** | Identify with script 06 before migrating; items with unique permissions need special handling |
| **Modern Pages** | Always enable Feature `B6917CB1-93A0-4B97-A84D-7CF49975D4EC` on destination sites |
| **Audit** | Run scripts 01 and 06 (Audit) BEFORE and AFTER to compare states |

---

## References

- [PnP.PowerShell Docs](https://pnp.github.io/powershell/)
- [Microsoft SPMT](https://docs.microsoft.com/en-us/sharepointmigration/introducing-the-sharepoint-migration-tool)
- [SharePoint Provisioning Schema](https://github.com/pnp/PnP-Provisioning-Schema)
- [Site Designs & Scripts Reference](https://docs.microsoft.com/en-us/sharepoint/dev/declarative-customization/site-design-overview)
