Connect-ExchangeOnline
$users = Get-mailbox
$CustomResult=@()
foreach ($user in $users.UserPrincipalName){
#Get-mailbox $user | Get-Mailboxstatistics | select TotalItemSize

$Mailbox = Get-MailboxStatistics $user | Select DisplayName,MailboxTypeDetail
$MailboxStatistics = Get-MailboxStatistics $user | Select @{n=”Total Size (GB)”;e={[math]::Round(($_.TotalItemSize.ToString().Split("(")[1].Split(" ")[0].Replace(",","")/1GB),2)}}

$Archive = Get-ExoMailboxStatistics -Archive -Identity $user | select DisplayName,TotalItemSize

$CustomResult += [PSCustomObject] @{
User = $user
DisplayName = $Mailbox.DisplayName
MailboxTypeDetail = $Mailbox.MailboxTypeDetail
TotalSize = $MailboxStatistics
ArchiveSize = $Archive.TotalItemSize

}
#$CustomResult | FT
$CustomResult | Export-CSV "C:\Temp\O365-Mailbox.csv" -NoTypeInformation -Encoding UTF8

}