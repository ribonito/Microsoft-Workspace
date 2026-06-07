#Parameters
$CSVFile = "C:\Temp\TeamCreationTemplate.csv"
 
Try {
    #Read the CSV File
    $TeamsData = Import-CSV -Path $CSVFile
 
    #Connect to Microsoft Teams
    Connect-MicrosoftTeams
 
    #Iterate through the CSV
    ForEach($Team in $TeamsData)
    {
        Try {
            #Create a New Team
            Write-host -f Yellow "Creating Team:" $Team.TeamName
            $NewTeam = New-Team -DisplayName $Team.TeamName -Owner $Team.Owner -Description $Team.Description -Visibility $Team.Visibility -ErrorAction Stop
            Write-host "`tNew Team '$($Team.TeamName)' Created Successfully" -f Green
 
            #Add Members to the Team
            #Write-Host "`tAdding Team members..." -f Yellow
            #$Members = $Team.Members.Split(";")
            #ForEach($Member in $Members)
            #{
             #   Add-TeamUser -User $Member -GroupId $NewTeam.GroupID -Role Member
               # Write-host "`t`tAdded Team Member:'$($Member)'" -f Green
            #}
        }
        Catch {
            Write-host -f Red "Error Creating Team:" $_.Exception.Message
        }
    }
}
Catch {
    Write-host -f Red "Error:" $_.Exception.Message
}


#Read more: https://www.sharepointdiary.com/2021/04/how-to-bulk-create-microsoft-teams-using-powershell.html#ixzz8hNu9hUzR