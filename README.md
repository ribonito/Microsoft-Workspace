# Microsoft Workspace – Administración Avanzada M365

Repositorio centralizado de scripts PowerShell, plantillas y documentación para administradores avanzados de **Microsoft 365**, **Entra ID**, **Exchange Online**, **Teams**, **SharePoint**, **Intune** y entornos híbridos.

---

## Estructura del repositorio

```
Microsoft-Workspace/
├── Cloud_Scripts/              # Administración cloud-native
│   ├── Azure/                  # Monitorización y recursos Azure
│   ├── Entra_ID/               # Identidad, CA, dispositivos
│   ├── Exchange_Management/    # EXO, Defender, mail-flow
│   ├── Intune/                 # Endpoint Manager, Autopilot, Win32
│   ├── M365_Assessment/        # Informes cross-service (licencias, SPO, seguridad)
│   ├── Migration/              # Herramientas de migración (BitTitan, etc.)
│   ├── Office_Apps/            # Click-to-Run y activación local
│   ├── Security_and_Compliance/ # Purview / Compliance Center (extensible)
│   ├── SharePoint/             # SPO, migraciones PnP, provisioning
│   ├── Teams/                  # Inventario, retención, telefonía
│   └── Utilities/              # Conexión, módulos, plantillas
│       ├── Connection/         # Conectores por servicio (UTL-009 a UTL-019)
│       ├── Common/             # Funciones auxiliares (UTL-020, UTL-021)
│       └── Templates/          # Plantillas de script/función (UTL-022, UTL-023)
├── OnPremises_Scripts/         # AD, Exchange on-prem, endpoints locales
├── Governance_and_Policies/    # Marcos de gobernanza y políticas
├── Reports/                    # Salidas CSV/HTML generadas (gitignored)
├── Templates/                  # Plantillas CA, CSV de equipos, etc.
├── SCRIPT_INDEX.md             # Catálogo completo de scripts
└── README.md
```

---

## Convención de nombres

```
<PREFIJO>-<NNN>_<DescripcionCorta>.ps1
```

| Prefijo | Tecnología / Producto |
|---------|----------------------|
| `EXO` | Exchange Online / Defender for Office 365 |
| `SPO` | SharePoint Online / PnP |
| `TEA` | Microsoft Teams |
| `M365` | Assessment cross-service / Microsoft Graph |
| `INT` | Microsoft Intune / Autopilot |
| `UTL` | Utilidades (conexión, módulos, helpers) |
| `OPR` | On-Premises (Citrix, Exchange Server) |
| `MIG` | Migración |

---

## Inicio rápido

```powershell
# 1. Política de ejecución (sesión actual)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

# 2. Instalar módulos M365
.\OnPremises_Scripts\Utilities\UTL-005_Install-PSModules.ps1

# 3. Conectar a todos los servicios
.\Cloud_Scripts\Utilities\UTL-001_Connect-O365Services.ps1

# 4. Consultar el catálogo
Get-Content .\SCRIPT_INDEX.md
```

---

## Flujos de trabajo recomendados

Ver el mapa completo en **[SCRIPT_INDEX.md](SCRIPT_INDEX.md#workflow-map-recommended-execution-order)**.

| Fase | Scripts clave |
|------|---------------|
| **Assessment** | `M365-001` → `M365-014`, `TEA-001` → `TEA-004`, `SPO-001` |
| **Hardening** | `EXO-005` → `EXO-001` → `EXO-004` |
| **Migración SPO** | `SPO-001` → `SPO-003` → `SPO-005` → `SPO-006` |
| **Intune** | `INT-001` → `INT-002` → `INT-005` |

---

## Estándares de código

1. **Cabeceras en inglés** con comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.EXAMPLE`)
2. **Regiones de 79 caracteres** para navegación en IDE (`#region ── Parameters ──`)
3. **Validación AST** antes de commit: `[System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$errs)`

---

## Seguridad

No subas credenciales, certificados ni datos de clientes. Usa autenticación por certificado (CBA) o MFA según `UTL-001_Connect-O365Services.ps1`.

---

**Maintainer:** Josep Canas – M365 Solutions Architect
