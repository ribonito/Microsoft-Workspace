# Entra ID (Azure AD)

Identity, device, and Conditional Access scripts.

| Script | Description |
|--------|-------------|
| `M365-007_Export-CAPolicies.ps1` | Export Conditional Access policies |
| `M365-009_Export-AzureADDevices.ps1` | Inventory of devices registered in Entra ID |

## Requirements

```powershell
Install-Module Microsoft.Graph -Force
.\Cloud_Scripts\Utilities\Connection\UTL-010_Connect-AzureAD.ps1
```
