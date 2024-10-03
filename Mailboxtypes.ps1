Connect-ExchangeOnline

#Enable remote mailboxes in Exo with PS from a csv file 
Import-Csv -Path "C:\Users\canasmarin\downloads\enable_remote.csv" | ForEach-Object {
    Enable-RemoteMailbox -Identity $_.samaccountname -RemoteRoutingAddress $_.userprincipalname -Shared
}
