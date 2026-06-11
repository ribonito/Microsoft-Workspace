<#
.SYNOPSIS
    UTL-004 | Utility - Update and Maintain All Microsoft 365 PowerShell Modules.

.DESCRIPTION
    Checks for updates to a defined set of Microsoft 365 PowerShell modules from the
    PowerShell Gallery and applies any available updates. After updating, removes older
    versions of the same modules to keep the system clean.

    Modules covered by default:
        MicrosoftTeams, Microsoft.Graph, Microsoft.Graph.Beta, ExchangeOnlineManagement,
        Microsoft.Online.Sharepoint.PowerShell, ORCA, Az.Accounts, Az.Automation,
        AIPService, Az.Keyvault, Pnp.PowerShell, MSCommerce, Microsoft365DSC, MSAL.PS,
        WhiteboardAdmin, ImportExcel, Microsoft.Identity.Client

    Requires PowerShell 7+ and must be run as Administrator.

.PRODUCT
    Microsoft 365 (multi-module utility)

.ORIGINAL_AUTHOR
    Office 365 for IT Pros - https://github.com/12Knocksinna/Office365itpros
    Script: UpdateOffice365PowerShellModules.PS1
    Mentioned in Chapter 4 of "Office 365 for IT Pros"
    V2.0 4-Dec-2022 | V2.1 9-Apr-2023 | V2.2 28-Apr-2023
    V2.3 9-Jul-2023  (Microsoft Graph PowerShell SDK V2.0 support)
    V2.4 12-Aug-2023 (PowerShell V5 and V7 compatibility)
    V2.5 25-Oct-2024 (Admin rights check + PowerShell 7 check)

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-004 classification & English header)

.VERSION
    2.6

.NOTES
    - Requires PowerShell 7+
    - Must be run as Administrator (elevated session)
    - Reference: https://github.com/12Knocksinna/Office365itpros/blob/master/UpdateOffice365PowerShellModules.PS1
    - For production use, review module list and validate in non-production first

.EXAMPLE
    .\UTL-004_Update-M365PSModules.ps1
#>

#region ── Pre-Execution Checks ────────────────────────────────────────────────
# Check that we have administrator rights to install and update modules
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
If (!$IsAdmin) {
    Write-Host "You must be signed in as an administrator to update modules" -ForegroundColor Red
    Break
}
If ($Host.Version.Major -lt 7) {
    Write-Host ("Current version is {0}. This script requires PowerShell 7" -f $Host.Version) -ForegroundColor Red
    Break
}
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Define the set of modules installed and updated from the PowerShell Gallery that we want to maintain - edit this set of modules to include the modules 
# you want to process.
[int]$InstalledModules = 0; [int]$UpdatedModules = 0; [int]$RemovedModules = 0
$O365Modules = @("MicrosoftTeams", "Microsoft.Graph", "Microsoft.Graph.Beta", "ExchangeOnlineManagement", "Microsoft.Online.Sharepoint.PowerShell", "ORCA", "Az.Accounts", "Az.Automation", "AIPService", "Az.Keyvault", "Pnp.PowerShell", "MSCommerce", "Microsoft365DSC", "MSAL.PS", "WhiteboardAdmin", "ImportExcel", "Microsoft.Identity.Client")
$O365Modules = $O365Modules | Sort-Object
Write-Host ("Starting up and preparing to process these modules: {0}" -f ($O365Modules -join ", ")) -foregroundcolor Yellow
[int]$UpdatedModules = 0; [int]$RemovedModules = 0; [int]$InstalledModules = 0

# We're installing from the PowerShell Gallery so make sure that it's trusted
Set-PSRepository -Name PsGallery -InstallationPolicy Trusted

# Check and update all modules to make sure that we're at the latest version
ForEach ($Module in $O365Modules) {
   Write-Host "Checking and updating module" $Module
   $CurrentModule = Find-Module -Name $Module
   If ($CurrentModule) {
     $CurrentVersion = $CurrentModule.Version
      If ($CurrentVersion -isnot [string]) {
        $CurrentVersion = $CurrentVersion.Major.toString() + "." + $CurrentVersion.Minor.toString() + "." + $CurrentVersion.Build.toString()
      }
     [datetime]$CurrentModuleDate = $CurrentModule.PublishedDate
     Write-Host ("Current version of the {0} module in the PowerShell Gallery is {1}" -f $Module, $CurrentVersion)
   }

   $PCModule = Get-InstalledModule -Name $Module -ErrorAction SilentlyContinue

   If (!($PCModule)) { 
   # No version of the module found. It's in our list, so we install it.
     Write-Host ("No module found on this PC for {0}" -f $Module)
     Write-Host ("Installing module {0}..." -f $Module)  -foregroundcolor Yellow
     Install-Module $Module -Scope AllUsers -Confirm:$False -AllowClobber -Force
     $InstalledModules++
   }

   If ($PCModule) {
      $PCVersion = $PCModule.Version
      If ($PCVersion -isnot [string]) {
         $PCVersion = $PCVersion.Major.toString() + "." + $PCVersion.Minor.toString() + "." + $PCVersion.Build.toString()
      }
      [datetime]$PCModuleDate = $PCModule.PublishedDate

      If ($PCModuleDate -eq $CurrentModuleDate) { 
         Write-Host ("Latest version of {0} is installed on this PC - no need to update" -f $Module) 
      } Else {
         Write-Host ("Updating {0} module to version {1}" -f $Module, $CurrentVersion) -foregroundcolor Yellow
         Remove-Module $Module -ErrorAction SilentlyContinue
         Update-Module $Module -Force -Confirm:$False -Scope AllUsers
         $UpdatedModules++
       } # End if 
     }
} # End ForEach Module

# Check and remove older versions of the modules from the PC
Write-Host "Beginning clean-up phase..."
[array]$SetofInstalledModules = Get-InstalledModule
[array]$GraphModules = $SetOfInstalledModules | Where-Object {$_.Name -Like "*Microsoft.Graph*"} | Select-Object -ExpandProperty Name
$ModulesToProcess = $O365Modules + $GraphModules | Sort-Object -Unique

ForEach ($Module in $ModulesToProcess) {
   Write-Host "Checking for older versions of" $Module
   [array]$AllVersions = Get-InstalledModule -Name $Module -AllVersions -ErrorAction SilentlyContinue
   If ($AllVersions) {
     $AllVersions = $AllVersions | Sort-Object PublishedDate -Descending 
     $MostRecentVersion = $AllVersions[0].Version
     If ($MostRecentVersion -isnot [string]) { # Handle PowerShell 5 - PowerShell 7 returns a string
        $MostRecentVersion = $MostRecentVersion.Major.toString() + "." + $MostRecentVersion.Minor.toString() + "." + $MostRecentVersion.Build.toString()
     }
     [datetime]$MostRecentVersionDate = $AllVersions[0].PublishedDate
     $PublishedDate = (Get-Date($MostRecentVersionDate) -format g)
     Write-Host ("Most recent version of {0} is {1} published on {2}" -f $Module, $MostRecentVersion, $PublishedDate)
     If ($AllVersions.Count -gt 1 ) { # More than a single version installed
      ForEach ($Version in $AllVersions) { #Check each version and remove old versions
        [datetime]$VersionDate = $Version.PublishedDate
        If ($VersionDate -lt $MostRecentVersionDate)  { # Old version - remove
           Write-Host ("Uninstalling version {0} of module {1}" -f $Version.Version, $Module) -foregroundcolor Red 
           Uninstall-Module -Name $Module -RequiredVersion $Version.Version -Force
           $RemovedModules++
         } #End if version check
       } # End ForEach versions 
     } Else {
         Write-Host ("No earlier versions of {0} module to remove" -f $Module)
     } # End check for more than one version
   } #End If
} #End ForEach

Write-Host ("Installed modules: {0} Updated modules: {1}  Removed old versions of modules: {2}" -f $InstalledModules, $UpdatedModules, $RemovedModules)
#endregion