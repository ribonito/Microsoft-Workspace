<#
.SYNOPSIS
    Inventories and verifies installation of Microsoft 365 administrative PowerShell modules.

.DESCRIPTION
    Audits the local system for the presence and installed versions of critical Microsoft 365
    PowerShell modules, including ExchangeOnlineManagement, MicrosoftTeams, Microsoft.Graph,
    AzureAD, PnP.PowerShell, and SharePoint Online. Produces a structured report with an optional CSV export.

.PARAMETER ExportReport
    Switch to export the module overview report to a CSV file.

.PARAMETER ExportReportPath
    Destination directory where the CSV report will be written. Defaults to the user's Downloads folder.

.PARAMETER Silent
    Suppresses console visual output and only returns the resulting collection.

.EXAMPLE
    Get-M365ModuleOverview
    Checks all standard M365 modules and prints status directly to the console.

.EXAMPLE
    Get-M365ModuleOverview -ExportReport -ExportReportPath "$env:USERPROFILE\Desktop"
    Inventories installed modules and saves the result to a CSV file on the desktop.

.OUTPUTS
    [PSCustomObject]
    Objects containing Module name, Version, and Installation status.

.NOTES
    Author: Josep Canas - M365 Solutions Architect
    Product: Microsoft 365 Administrative Tools
    Version: 2.0

.LINK
    https://learn.microsoft.com/microsoft-365/enterprise/connect-to-all-office-365-services-in-a-single-windows-powershell-window
    https://learn.microsoft.com/powershell/gallery/overview
#>
function Get-M365ModuleOverview {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$ExportReport,

        [Parameter(Mandatory = $false)]
        [string]$ExportReportPath = "$env:USERPROFILE\Downloads",

        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )

    begin {
        if (-not $Silent) {
            Write-Host "`n=== Microsoft 365 PowerShell Module Inventory ===" -ForegroundColor Cyan
        }

        $ListAllModules = @(
            "AIPService",
            "AzureAD",
            "AzureADPreview",
            "ExchangeOnlineManagement",
            "Microsoft.Graph",
            "Microsoft.Online.SharePoint.PowerShell",
            "MicrosoftTeams",
            "MSCommerce",
            "MSOnline",
            "NetworkTestingCompanion",
            "PnP.PowerShell"
        )
        $Report = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    process {
        foreach ($m in ($ListAllModules | Sort-Object)) {
            if (-not $Silent) {
                Write-Host "Checking module " -NoNewline
                Write-Host $m -NoNewline -ForegroundColor Yellow
                Write-Host "... " -NoNewline
            }

            $GetModule = Get-Module -ListAvailable -Name $m -ErrorAction SilentlyContinue

            if ($null -eq $GetModule) {
                if (-not $Silent) {
                    Write-Host "NOT INSTALLED" -ForegroundColor Red
                }
                $Report.Add([PSCustomObject]@{
                    Module    = $m
                    Installed = $false
                    Version   = "n/a"
                    Path      = "n/a"
                })
            }
            else {
                $versions = ($GetModule | ForEach-Object { $_.Version.ToString() }) -join ", "
                $paths = ($GetModule | ForEach-Object { $_.ModuleBase }) -join "; "

                if (-not $Silent) {
                    Write-Host "INSTALLED " -NoNewline -ForegroundColor Green
                    Write-Host "($versions)" -ForegroundColor Gray
                }

                $Report.Add([PSCustomObject]@{
                    Module    = $m
                    Installed = $true
                    Version   = $versions
                    Path      = $paths
                })
            }
        }
    }

    end {
        if ($ExportReport) {
            if (-not (Test-Path -Path $ExportReportPath)) {
                New-Item -ItemType Directory -Path $ExportReportPath -Force | Out-Null
            }
            $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $CsvFile = Join-Path -Path $ExportReportPath -ChildPath "M365ModuleOverview_$Timestamp.csv"
            $Report | Export-Csv -Path $CsvFile -NoTypeInformation -Encoding utf8
            Write-Host "Report exported: $CsvFile" -ForegroundColor Green
        }
        return $Report
    }
}