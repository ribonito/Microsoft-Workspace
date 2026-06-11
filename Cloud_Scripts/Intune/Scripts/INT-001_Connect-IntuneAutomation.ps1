<#
.SYNOPSIS
    INT-001 | Intune / Microsoft Graph - Automated Connection via Client Credentials.

.DESCRIPTION
    Authenticates to Microsoft Graph using the OAuth 2.0 Client Credentials flow
    (app-only, non-interactive). Suitable for use in automation pipelines,
    scheduled tasks, and CI/CD processes where interactive login is not possible.

    Steps:
        1. Requests an access token from the Entra ID token endpoint
        2. Converts the token to a SecureString
        3. Connects to Microsoft Graph with Connect-MgGraph

    IMPORTANT: Replace the placeholder values for TenantID, ClientID, and
    ClientSecret with your own App Registration details. Do NOT commit
    credentials to source control — use Azure Key Vault or environment variables.

.PRODUCT
    Microsoft Intune / Microsoft Graph

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    .\INT-001_Connect-IntuneAutomation.ps1

.NOTES
    - Module: Microsoft.Graph.Authentication
    - Requires an Entra ID App Registration with appropriate Graph scopes
    - For production use, replace ClientSecret with certificate-based auth
#>

#region ── App Registration Configuration ────────────────────────────────────
# IMPORTANT: Replace these values. Do NOT store secrets in source control.
# Use environment variables or Azure Key Vault in production.
$TenantID     = $env:INTUNE_TENANT_ID     # e.g. "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$ClientID     = $env:INTUNE_CLIENT_ID     # e.g. "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy"
$ClientSecret = $env:INTUNE_CLIENT_SECRET # App Registration client secret
#endregion

#region ── Request Access Token ───────────────────────────────────────────────
$Body = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    Client_Id     = $ClientID
    Client_Secret = $ClientSecret
}

$Connection = Invoke-RestMethod `
    -Uri    "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token" `
    -Method POST `
    -Body   $Body

$Token = $Connection.access_token | ConvertTo-SecureString -AsPlainText -Force
#endregion

#region ── Connect to Microsoft Graph ────────────────────────────────────────
try {
    Connect-MgGraph -AccessToken $Token -NoWelcome
    Write-Host "Successfully connected to Microsoft Graph." -ForegroundColor Green
} catch {
    Write-Host "Error connecting to Microsoft Graph: $_" -ForegroundColor Red
}
#endregion
