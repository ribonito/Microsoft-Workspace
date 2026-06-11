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
    .\INT-006_Get-Users-Last-Signins.ps1
#>

#region ── Connection ─────────────────────────────────────────────────────────
Connect-MgGraph -Scopes Directory.Read.All, AuditLog.Read.All -NoWelcome
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
$OutputPath = "C:\temp\userlogins.csv"
$OutputDir  = Split-Path $OutputPath

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Get-MgUser -All -Property 'UserPrincipalName', 'SignInActivity', 'Mail', 'DisplayName' | 
    Select-Object @{N='UserPrincipalName'; E={$_.UserPrincipalName}}, 
                  @{N='DisplayName'; E={$_.DisplayName}}, 
                  @{N='LastSignInDate'; E={$_.SignInActivity.LastSignInDateTime}} | 
    Export-Csv -Path $OutputPath -NoTypeInformation -Force

Write-Host -ForegroundColor Green "User last sign-ins report exported to: $OutputPath"
#endregion
