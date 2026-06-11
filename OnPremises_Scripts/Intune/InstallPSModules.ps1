<#
.SYNOPSIS
    UTL-005 | Utility - Install All Required Microsoft 365 PowerShell Modules.

.DESCRIPTION
    Installs all PowerShell modules needed to manage Microsoft 365 services.
    Run once on a new administrator workstation or build machine.

    Modules installed:
        - Microsoft.Online.SharePoint.PowerShell
        - Az (Azure PowerShell)
        - ExchangeOnlineManagement
        - MicrosoftTeams
        - MSOnline (Azure AD v1 - legacy)
        - SharePointPnPPowerShellOnline (legacy PnP)
        - Microsoft.Graph
        - Microsoft.Graph.Beta
        - MSGraphFunctions
        - IntuneBackupAndRestore
        - WindowsAutopilotPartnerCenter

    NOTE: Run as Administrator. Some modules require AllUsers scope.

.PRODUCT
    Microsoft 365 (multi-service utility)

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - Must be run in an elevated (Administrator) PowerShell session
    - Internet access required to reach the PowerShell Gallery
    - For module updates, use UTL-004 instead

.EXAMPLE
    .\UTL-005_Install-PSModules.ps1
    (Run as Administrator)
#>


install-module -name Microsoft.Online.SharePoint.PowerShell -Force
install-module -name az -Force
install-module -name ExchangeOnlineManagement -Force
install-module -name MicrosoftTeams -Force
install-module -name MSOnline -Force
install-module -name SharePointPnPPowerShellOnline -Force
Install-Module -name Microsoft.Graph -Force
Install-Module -name Microsoft.Graph.beta -Force
Install-Module -Name MSGraphFunctions -Force
Install-Module -Name IntuneBackupAndRestore -Force
Install-Module -Name WindowsAutopilotPartnerCenter –force

