# Entra ID (Azure AD)

Scripts de identidad, dispositivos y acceso condicional.

| Script | Descripción |
|--------|-------------|
| `M365-007_Export-CAPolicies.ps1` | Exportar políticas de Acceso Condicional |
| `M365-009_Export-AzureADDevices.ps1` | Inventario de dispositivos registrados en Entra ID |

## Requisitos

```powershell
Install-Module Microsoft.Graph -Force
.\Cloud_Scripts\Utilities\Connection\UTL-010_Connect-AzureAD.ps1
```
