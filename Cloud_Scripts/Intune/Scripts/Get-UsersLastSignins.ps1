# get all users with last sign-in dates

Connect-MgGraph -Scopes Directory.Read.All,AuditLog.Read.All
Get-MgUser -All -Property 'UserPrincipalName','SignInActivity','Mail','DisplayName' | Select-Object @{N='UserPrincipalName';E={$_.UserPrincipalName}}, @{N='DisplayName';E={$_.DisplayName }}, @{N='LastSignInDate';E={$_.SignInActivity.LastSignInDateTime}} | Export-Csv -Path C:\temp\userlogins.csv -NoTypeInformation -NoClobber
