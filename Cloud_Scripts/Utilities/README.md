# Utilities

Cross-cutting tools for connectivity, maintenance, and templates.

## Structure

| Folder | Contents |
|--------|----------|
| `Connection/` | Individual per-service connectors (EXO, Teams, SPO, Graph, etc.) |
| `Common/` | Reusable functions (`Get-Timestamp`, `Get-RandomAlphaNumString`) |
| `Templates/` | Templates for new scripts and functions |
| *(root)* | Multi-service connector, module updates, general utilities |

## Recommended Entry Point

```powershell
# Connect to all M365 services at once
.\UTL-001_Connect-O365Services.ps1

# Exchange Online and Teams only
.\UTL-001_Connect-O365Services.ps1 -Services ExchangeOnline, MSTeams
```
