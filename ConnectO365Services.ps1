# Import necessary modules
Import-Module Microsoft.Graph

# Function to connect to Microsoft 365 services using Microsoft Graph
function Connect-M365Services {
    param (
        [parameter(Mandatory = $true)]
        [string]$TenantId,
        [parameter(Mandatory = $true)]
        [string]$ClientId,
        [parameter(Mandatory = $true)]
        [SecureString]$ClientSecret
    )

    try {
        # Convert SecureString to plain text
        $ClientSecretPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret))

        # Connect to Microsoft Graph
        $Scopes = @("https://graph.microsoft.com/.default")
        $TokenRequestBody = @{
            Grant_Type    = "client_credentials"
            Scope         = [string]::Join(" ", $Scopes)
            Client_Id     = $ClientId
            Client_Secret = $ClientSecretPlainText
        }

        $TokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $TokenRequestBody
        $AccessToken = $TokenResponse.access_token

        # Set the access token for Microsoft Graph
        $Headers = @{
            Authorization = "Bearer $AccessToken"
        }

        Write-Output "Connected to Microsoft Graph successfully."
        return $Headers
    } catch {
        Write-Output "Failed to connect to Microsoft Graph: $_" -ForegroundColor Red
        exit 1
    }
}

# Example usage
$TenantId = "your-tenant-id"
$ClientId = "your-client-id"
$ClientSecret = Read-Host -Prompt "Enter Client Secret" -AsSecureString

$Headers = Connect-M365Services -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret

# Example of using the headers to make a Microsoft Graph API call
try {
    $Users = Invoke-RestMethod -Headers $Headers -Uri "https://graph.microsoft.com/v1.0/users" -Method Get
    $Users | Format-Table DisplayName, UserPrincipalName
} catch {
    Write-Output "Failed to retrieve users: $_" -ForegroundColor Red
}

# Example of using the headers to make another Microsoft Graph API call
try {
    $Groups = Invoke-RestMethod -Headers $Headers -Uri "https://graph.microsoft.com/v1.0/groups" -Method Get
    $Groups | Format-Table DisplayName, Mail
} catch {
    Write-Output "Failed to retrieve groups: $_" -ForegroundColor Red
}