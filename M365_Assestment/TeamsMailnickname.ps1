Connect-MicrosoftTeams

$Teams = Get-Team

$FolderPath = 'c:\temp\uniqueusers.csv'

$users = @()

ForEach( $i in $Teams.GroupId){

$users += Get-TeamUser -GroupId $i

}

$uniqUsers = $users | sort UserId -Unique

$uniqUsers | Export-Csv -Path $FolderPath 