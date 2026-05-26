function Export-TeamsList {
    param (
        [parameter(Mandatory = $true)]
        [string]$ExportPath
    )
    process {
        try {
            # Connect to Microsoft Graph with the required scopes
            Connect-PnPMicrosoftGraph -Scopes "Group.Read.All", "User.ReadBasic.All"
            $accesstoken = Get-PnPAccessToken

            # Get the list of groups with the type 'Unified' (Microsoft 365 Groups)
            $group = Invoke-RestMethod -Headers @{ Authorization = "Bearer $accesstoken" } -Uri "https://graph.microsoft.com/v1.0/groups?`$filter=groupTypes/any(c:c+eq+`'Unified`')" -Method Get
            $TeamsList = @()

            do {
                foreach ($value in $group.value) {
                    Write-Output "Group Name: $($value.displayName) Group Type: $($value.groupTypes)"
                    if ($value.groupTypes -contains "Unified") {
                        $id = $value.id
                        try {
                            # Get the channels for the team
                            $team = Invoke-RestMethod -Headers @{ Authorization = "Bearer $accesstoken" } -Uri "https://graph.microsoft.com/v1.0/Groups/$id/channels" -Method Get
                            Write-Output "Channel count for $($value.displayName) is $($team.value.Count)"
                        } catch {
                            Write-Output "Could not get channels for $($value.displayName). $($_.Exception.Message)" -ForegroundColor Red
                            $team = $null
                        }

                        if ($team.value.Count -ge 1) {
                            # Get the owners of the team
                            $Owner = Invoke-RestMethod -Headers @{ Authorization = "Bearer $accesstoken" } -Uri "https://graph.microsoft.com/v1.0/Groups/$id/owners" -Method Get
                            $Teams = [PSCustomObject]@{
                                TeamsName    = $value.displayName
                                TeamType     = $value.visibility
                                ChannelCount = $team.value.Count
                                ChannelName  = ($team.value.displayName -join ";")
                                Owners       = ($Owner.value.userPrincipalName -join ";")
                            }
                            $TeamsList += $Teams
                        }
                    }
                }

                # Check if there is a next page of results
                if ($group.'@odata.nextLink' -eq $null) {
                    break
                } else {
                    $group = Invoke-RestMethod -Headers @{ Authorization = "Bearer $accesstoken" } -Uri $group.'@odata.nextLink' -Method Get
                }
            } while ($true)

            # Export the list of teams to a CSV file
            $TeamsList | Export-Csv -Path $ExportPath -NoTypeInformation
        } catch {
            Write-Output "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Example usage
$ExportPath = "C:\Temp\TeamsList.csv"
Export-TeamsList -ExportPath $ExportPath