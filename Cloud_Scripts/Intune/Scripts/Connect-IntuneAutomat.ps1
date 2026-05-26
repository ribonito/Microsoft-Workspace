# Populate with the App Registration details and Tenant ID

#App Registration details
$TenantID = "0b57e92f-4bfc-4513-81af-dff5bed4c391"
$ClientID = "de32e5d4-2bf2-47c5-a1e4-0c15aef1375e"
$ClientSecret = "KTV8Q~Llkdvty8M-bYO-tFqVLPtKWK~PuBeS6dw1"
 
$Body =  @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    Client_Id     = $ClientID
    Client_Secret = $ClientSecret
}
 
$Connection = Invoke-RestMethod `
    -Uri https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token `
    -Method POST `
    -Body $body
 
#Get the Access Token
$Token = $Connection.access_token | ConvertTo-SecureString -AsPlainText -Force
 
# Connect to Microsoft Graph
try {
    Connect-MgGraph -AccessToken $Token -NoWelcome
    Write-Host "Connected to Microsoft Graph successfully." -ForegroundColor Green
} catch {
    Write-Host "Error connecting to Microsoft Graph: $_" -ForegroundColor Red
}
