<#
.SYNOPSIS
    INT-006 | Intune / Entra ID - Export All Users' Last Sign-In Date to CSV.

.DESCRIPTION
    Connects to Microsoft Graph and retrieves the last sign-in date for every user
    in the tenant using the SignInActivity property.

    Output columns: UserPrincipalName, DisplayName, LastSignInDate.
    Export path: C:\temp\userlogins.csv

    Useful for:
        - Identifying inactive/stale user accounts for license reclamation
        - Access review and governance
        - Pre-migration active user count

.PRODUCT
    Microsoft Entra ID / Microsoft Graph

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - Module: Microsoft.Graph.Users
    - Required scopes: Directory.Read.All, AuditLog.Read.All
    - The SignInActivity property requires Entra ID P1 or P2
    - Output: C:\temp\userlogins.csv

.EXAMPLE
    .\INT-006_Get-UsersLastSignin.ps1
#>

# Get all users with last sign-in dates via Microsoft Graph
Connect-MgGraph -Scopes Directory.Read.All,AuditLog.Read.All
Get-MgUser -All -Property 'UserPrincipalName','SignInActivity','Mail','DisplayName' | Select-Object @{N='UserPrincipalName';E={$_.UserPrincipalName}}, @{N='DisplayName';E={$_.DisplayName }}, @{N='LastSignInDate';E={$_.SignInActivity.LastSignInDateTime}} | Export-Csv -Path C:\temp\userlogins.csv -NoTypeInformation -NoClobber
