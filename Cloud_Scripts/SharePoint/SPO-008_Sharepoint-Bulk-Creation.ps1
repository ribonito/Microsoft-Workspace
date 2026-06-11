<#
.SYNOPSIS
    SPO-008 | SharePoint Online / Microsoft Teams - Bulk Create Teams from CSV.

.DESCRIPTION
    Reads a CSV template file containing team configurations and creates Microsoft Teams
    correspondingly, specifying names, owners, descriptions, and visibility.

.PRODUCT
    SharePoint Online / Microsoft Teams

.AUTHOR
    Josep Canas - M365 Solutions Architect (SPO-008 classification & template)

.VERSION
    1.1

.EXAMPLE
    .\SPO-008_Sharepoint-Bulk-Creation.ps1

.NOTES
    - Requires the MicrosoftTeams PowerShell module.
    - CSV Template Path is set to C:\Temp\TeamCreationTemplate.csv.
    - Reference: https://www.sharepointdiary.com/2021/04/how-to-bulk-create-microsoft-teams-using-powershell.html
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$CSVFile = "C:\Temp\TeamCreationTemplate.csv"
#endregion

#region ── Process Execution ──────────────────────────────────────────────────
Try {
    # Read the CSV File
    $TeamsData = Import-CSV -Path $CSVFile
 
    # Connect to Microsoft Teams
    Connect-MicrosoftTeams
 
    # Iterate through the CSV
    ForEach ($Team in $TeamsData) {
        Try {
            # Create a New Team
            Write-Host -ForegroundColor Yellow "Creating Team: $($Team.TeamName)"
            $NewTeam = New-Team -DisplayName $Team.TeamName -Owner $Team.Owner -Description $Team.Description -Visibility $Team.Visibility -ErrorAction Stop
            Write-Host "`tNew Team '$($Team.TeamName)' Created Successfully" -ForegroundColor Green
 
            # Add Members to the Team (Optional - commented out)
            # Write-Host "`tAdding Team members..." -ForegroundColor Yellow
            # $Members = $Team.Members.Split(";")
            # ForEach($Member in $Members) {
            #     Add-TeamUser -User $Member -GroupId $NewTeam.GroupID -Role Member
            #     Write-Host "`t`tAdded Team Member:'$($Member)'" -ForegroundColor Green
            # }
        }
        Catch {
            Write-Host -ForegroundColor Red "Error Creating Team: $($_.Exception.Message)"
        }
    }
}
Catch {
    Write-Host -ForegroundColor Red "Error: $($_.Exception.Message)"
}
#endregion
