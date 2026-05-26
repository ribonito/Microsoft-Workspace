$Workspaces = Get-PowerBIWorkspace -Scope Organization -All
Login-PowerBIServiceAccount
$Reports =
ForEach ($workspace in $Workspaces)
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

