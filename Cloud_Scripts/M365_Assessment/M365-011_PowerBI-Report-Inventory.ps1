<#
.SYNOPSIS
    M365-011 | Power BI - Export Power BI Report Inventory.

.DESCRIPTION
    Logs into the Power BI Service and retrieves a complete inventory of all Power BI workspaces
    and their contained reports. Exports the results to a CSV file.

    Export fields:
        - WorkspaceID
        - WorkspaceName
        - ReportID
        - ReportName
        - ReportURL
        - ReportDatasetID

.PRODUCT
    Microsoft Power BI / Service

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - Requires the MicrosoftPowerBIMgmt module.
    - Prompts interactively for Power BI Administrator credentials.
    - Exports to C:\temp\reports.csv (ensure C:\temp exists or change path if needed).

.EXAMPLE
    .\M365-011_PowerBI-Report-Inventory.ps1
#>

#region ── Authentication ─────────────────────────────────────────────────────
Login-PowerBIServiceAccount
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
$Workspaces = Get-PowerBIWorkspace -Scope Organization -All
$Reports = ForEach ($workspace in $Workspaces)
    {
    Write-Host $workspace.Name
    ForEach ($report in (Get-PowerBIReport -Scope Organization -WorkspaceId $workspace.Id))
        {
        [pscustomobject]@{
            WorkspaceID = $workspace.Id
            WorkspaceName = $workspace.Name
            ReportID = $report.Id
            ReportName = $report.Name
            ReportURL = $report.WebUrl
            ReportDatasetID = $report.DatasetId
            }
        }
    }
$Reports | Export-Csv -Path C:\temp\reports.csv -NoTypeInformation
#endregion
