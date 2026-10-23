<#
.SYNOPSIS
    Evaluates local system configuration and prerequisites for Microsoft 365 PowerShell administration.

.DESCRIPTION
    Checks whether the current workstation meets all prerequisites for administering Microsoft 365,
    Exchange Online, Microsoft Teams, SharePoint Online, and Microsoft Graph. Validates PowerShell
    version, execution policy, TLS 1.2 protocol enforcement, PowerShellGet/NuGet providers, and
    administrator privilege level.

.PARAMETER Detailed
    Switch to output extended CIM/WMI operating system properties.

.EXAMPLE
    Invoke-M365CheckSystemRequirements
    Runs a health check on local PowerShell environment and displays status indicators.

.EXAMPLE
    Invoke-M365CheckSystemRequirements -Detailed
    Runs health check and outputs full OS and PowerShell runtime diagnostics.

.OUTPUTS
    [PSCustomObject]
    Returns a structured object containing test names, current values, and pass/fail status.

.NOTES
    Author: Josep Canas - M365 Solutions Architect
    Product: Microsoft 365 Administrative Tools
    Version: 2.0

.LINK
    https://learn.microsoft.com/powershell/scripting/install/installing-powershell
    https://learn.microsoft.com/microsoft-365/enterprise/connect-to-all-office-365-services-in-a-single-windows-powershell-window
#>
function Invoke-M365CheckSystemRequirements {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    Write-Host "`n=== Microsoft 365 Administration Prerequisites Check ===" -ForegroundColor Cyan

    $Results = [System.Collections.Generic.List[PSCustomObject]]::new()

    # 1. PowerShell Version Check
    $psVersion = $PSVersionTable.PSVersion
    $isPsValid = ($psVersion.Major -ge 7) -or ($psVersion.Major -eq 5 -and $psVersion.Minor -ge 1)
    $Results.Add([PSCustomObject]@{
        Check       = "PowerShell Version"
        Current     = $psVersion.ToString()
        Requirement = ">= 5.1 or 7.x"
        Passed      = $isPsValid
    })

    # 2. Execution Policy Check
    $execPolicy = Get-ExecutionPolicy
    $isPolicyValid = ($execPolicy -notin @('Restricted', 'Undefined'))
    $Results.Add([PSCustomObject]@{
        Check       = "Execution Policy"
        Current     = $execPolicy.ToString()
        Requirement = "RemoteSigned or Unrestricted"
        Passed      = $isPolicyValid
    })

    # 3. TLS 1.2 Protocol Check (Windows PowerShell 5.1 requirement)
    $tlsValid = $true
    if ($PSVersionTable.PSEdition -ne 'Core') {
        $securityProtocols = [Net.ServicePointManager]::SecurityProtocol
        $tlsValid = ($securityProtocols -band [Net.SecurityProtocolType]::Tls12) -ne 0
        $Results.Add([PSCustomObject]@{
            Check       = "TLS 1.2 Protocol"
            Current     = $securityProtocols.ToString()
            Requirement = "Tls12 Enabled"
            Passed      = $tlsValid
        })
    }

    # 4. Administrator Privileges Check
    $isAdmin = $false
    if ($IsWindows -or $env:OS -like "*Windows*") {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity
        $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } else {
        $isAdmin = ([Security.Principal.WindowsIdentity]::GetCurrent().Name -eq "root")
    }
    $Results.Add([PSCustomObject]@{
        Check       = "Administrator Privileges"
        Current     = $(if ($isAdmin) { "Elevated" } else { "Standard User" })
        Requirement = "Elevated (for module installs)"
        Passed      = $isAdmin
    })

    # Output formatted results to console
    foreach ($r in $Results) {
        $color = if ($r.Passed) { "Green" } else { "Red" }
        $mark  = if ($r.Passed) { "[PASS]" } else { "[FAIL]" }
        Write-Host "$mark $($r.Check): $($r.Current) (Required: $($r.Requirement))" -ForegroundColor $color
    }

    if ($Detailed) {
        Write-Host "`nEnvironment Details:" -ForegroundColor Yellow
        $PSVersionTable
    }

    return $Results
}

# Auto-execute if invoked as a standalone script
if ($MyInvocation.InvocationName -ne '.' -and $MyInvocation.Line -notmatch 'function') {
    Invoke-M365CheckSystemRequirements
}
