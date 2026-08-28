# Utilities

Herramientas transversales para conexión, mantenimiento y plantillas.

## Estructura

| Carpeta | Contenido |
|---------|-----------|
| `Connection/` | Conectores individuales por servicio (EXO, Teams, SPO, Graph…) |
| `Common/` | Funciones reutilizables (`Get-Timestamp`, `Get-RandomAlphaNumString`) |
| `Templates/` | Plantillas para nuevos scripts y funciones |
| *(raíz)* | Conector multi-servicio, actualización de módulos, utilidades generales |

## Punto de entrada recomendado

```powershell
# Conectar a todos los servicios M365 de una vez
.\UTL-001_Connect-O365Services.ps1

# Solo Exchange Online y Teams
.\UTL-001_Connect-O365Services.ps1 -Services ExchangeOnline, MSTeams
```
