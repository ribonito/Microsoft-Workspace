# 📦 SharePoint Online – Migration Scripts (PnP Modern)

Scripts de PowerShell para arquitectos de soluciones M365, basados en **PnP.PowerShell** (v2.x+).  
Cubren el ciclo completo de una migración: desde el análisis pre-migración hasta la validación post-migración.

---

## 🛠️ Requisitos previos

```powershell
# Instalar el módulo PnP moderno
Install-Module PnP.PowerShell -Force -AllowClobber

# Verificar versión
Get-Module PnP.PowerShell -ListAvailable | Select-Object Name, Version
```

### Autenticación recomendada (App-Only con certificado)

```powershell
# 1. Registrar aplicación en Entra ID con PnP
Register-PnPEntraIDApp `
    -ApplicationName "PnP-Migration-App" `
    -Tenant "contoso.onmicrosoft.com" `
    -OutPath "C:\Certs" `
    -CertificatePassword (ConvertTo-SecureString "MyPass!" -AsPlainText -Force) `
    -Scopes "Sites.FullControl.All","User.Read.All","Group.ReadWrite.All"
```

> **Permisos mínimos necesarios** (Graph + SharePoint):  
> `Sites.FullControl.All` · `User.Read.All` · `Group.ReadWrite.All` · `TermStore.ReadWrite.All`

---

## 📋 Scripts incluidos

| # | Script | Propósito | Tipo |
|---|--------|-----------|------|
| 01 | `SPO-001_PreMigration-Assessment.ps1` | Inventario completo pre-migración | Análisis |
| 02 | `SPO-002_SiteMigration-ClassicToModern.ps1` | Migración clásico → moderno | Migración |
| 03 | `SPO-003_TenantToTenant-Migration.ps1` | Migración Tenant a Tenant (T2T) | Migración |
| 04 | `SPO-004_HubSpoke-Provisioning.ps1` | Arquitectura Hub-Spoke completa | Provisioning |
| 05 | `SPO-005_PostMigration-Validation.ps1` | Validación y remediación post-migración | Validación |
| 06 | `SPO-006_Permissions-Management.ps1` | Gestión masiva de permisos | Gobernanza |
| 07 | `SPO-007_SiteDesigns-Management.ps1` | Site Designs y Site Scripts | Estandarización |

---

## 🔄 Flujo de trabajo recomendado

```
┌─────────────────────────────────────────────────────────────┐
│                    CICLO DE MIGRACIÓN M365                  │
└─────────────────────────────────────────────────────────────┘

  [01] Assessment      →  Conoce lo que tienes
       ↓
  [06] Permissions     →  Auditoría de permisos (modo Audit)
       ↓
  [07] Site Designs    →  Estandariza plantillas destino (Create)
       ↓
  [04] Hub-Spoke       →  Construye la arquitectura destino
       ↓
  [02] Classic→Modern  →  Migra sitios clásicos / On-Prem
    o
  [03] T2T Migration   →  Migra entre tenants
       ↓
  [06] Permissions     →  Remedia permisos (RemoveExternal, ReplaceGroup)
       ↓
  [05] Validation      →  Valida y autoremedía
       ↓
  [07] Site Designs    →  Aplica designs a sitios migrados (ApplyToSites)
```

---

## 📝 Uso rápido por script

### 01 – Assessment
```powershell
.\SPO-001_PreMigration-Assessment.ps1 `
    -TenantAdminUrl "https://contoso-admin.sharepoint.com" `
    -ClientId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" `
    -Thumbprint "AABB..." `
    -TenantId "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" `
    -OutputPath "C:\Reports\Assessment"
```

### 02 – Clásico a Moderno
```powershell
.\SPO-002_SiteMigration-ClassicToModern.ps1 `
    -SourceUrl "https://contoso.sharepoint.com/sites/Old" `
    -DestinationUrl "https://contoso.sharepoint.com/sites/New" `
    -ClientId "xxxx" -Thumbprint "AABB" -TenantId "yyyy" `
    -MigrateContent       # Incluye archivos
```

### 03 – Tenant a Tenant
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
**Formato del CSV de mapeo de usuarios:**
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

### 05 – Validación Post-Migración
```powershell
.\SPO-005_PostMigration-Validation.ps1 `
    -SourceUrl "https://contoso.sharepoint.com/sites/Old" `
    -DestUrl   "https://contoso.sharepoint.com/sites/New" `
    -ClientId "xxxx" -Thumbprint "AABB" -TenantId "yyyy" `
    -AutoRemediate    # Corrección automática de problemas comunes
```

### 06 – Gestión de Permisos
```powershell
# Auditoría
.\SPO-006_Permissions-Management.ps1 -SiteUrl "..." -Mode Audit ...

# Eliminar usuarios externos
.\SPO-006_Permissions-Management.ps1 -SiteUrl "..." -Mode RemoveExternal ...

# Reemplazar grupo de seguridad (útil en T2T)
.\SPO-006_Permissions-Management.ps1 -SiteUrl "..." -Mode ReplaceGroup `
    -OldGroupName "Source-Owners" -NewGroupName "Dest-Owners" ...
```

### 07 – Site Designs
```powershell
# Crear design desde JSON
.\SPO-007_SiteDesigns-Management.ps1 -Mode Create `
    -SiteDesignName "Departmental Template" `
    -SiteScriptJsonPath "C:\script.json" -WebTemplate "64" ...

# Aplicar design a múltiples sitios
.\SPO-007_SiteDesigns-Management.ps1 -Mode ApplyToSites `
    -SiteDesignName "Departmental Template" `
    -TargetSiteUrls @("https://contoso.sharepoint.com/sites/IT","...") ...

# Exportar catálogo completo
.\SPO-007_SiteDesigns-Management.ps1 -Mode ExportAll ...
```

---

## ⚠️ Consideraciones para el Arquitecto

| Aspecto | Recomendación |
|---------|---------------|
| **Throttling** | Usar `-PageSize 500` y añadir `Start-Sleep -Seconds 1` en loops grandes |
| **Versiones** | PnP.PowerShell v2.x es incompatible con el módulo SharePoint PnPOnlineCommands legado |
| **Certificados** | Usar certificados de 2048-bit mínimo; rotar cada 6 meses |
| **T2T** | Microsoft SPMT (SharePoint Migration Tool) es complementario para contenido masivo |
| **Permisos rotos** | Identificar con el script 06 antes de migrar; los ítems con permisos únicos requieren tratamiento especial |
| **Modern Pages** | Activar siempre el Feature `B6917CB1-93A0-4B97-A84D-7CF49975D4EC` en los sitios destino |
| **Auditoría** | Ejecutar script 01 y 06 (Audit) ANTES y DESPUÉS para comparar estados |

---

## 🔗 Referencias

- [PnP.PowerShell Docs](https://pnp.github.io/powershell/)
- [Microsoft SPMT](https://docs.microsoft.com/en-us/sharepointmigration/introducing-the-sharepoint-migration-tool)
- [SharePoint Provisioning Schema](https://github.com/pnp/PnP-Provisioning-Schema)
- [Site Designs & Scripts Reference](https://docs.microsoft.com/en-us/sharepoint/dev/declarative-customization/site-design-overview)
