<#
.SYNOPSIS
    M365-006 | M365 Assessment - SharePoint Online Site Usage Report via Microsoft Graph (App Auth).

.DESCRIPTION
    Uses an Entra ID App Registration (client credentials flow) to call the Microsoft Graph
    Reporting API and retrieve SharePoint Online site usage statistics for the last 30 days.

    Output: C:\Temp\siteusage.csv

    Graph endpoint used:
        GET /v1.0/reports/getSharePointSiteUsageDetail(period='D30')

    Columns in the report include: site URL, owner, storage used, file count, activity dates.

    NOTE: Update $ClientID and $TenantName with your own tenant values.
    $ClientSecret is prompted interactively for security.

.PRODUCT
    SharePoint Online / Microsoft Graph Reporting API

.ORIGINAL_AUTHOR
    SharePointDiary.com
    Reference: https://www.sharepointdiary.com/2019/11/sharepoint-online-usage-reports-using-graph-api-powershell.html

.MAINTAINER
    Josep Canas - M365 Solutions Architect (M365-006 classification & English header)

.VERSION
    1.1

.NOTES
    - No PowerShell module required (uses Invoke-RestMethod directly)
    - App Registration must have Reports.Read.All permission (or Sites.Read.All)
    - Output: C:\Temp\siteusage.csv

.EXAMPLE
    .\M365-006_SPO-UsageReport-Graph.ps1
    (You will be prompted for the Client Secret)
#>

#https://www.sharepointdiary.com/2019/11/sharepoint-online-usage-reports-using-graph-api-powershell.html

# Function to Call Graph API
Function Get-UsageReport {
    param (
        [parameter(Mandatory = $true)] [string]$ClientID,
        [parameter(Mandatory = $true)] [string]$ClientSecret,
        [parameter(Mandatory = $true)] [string]$TenantName,
        [parameter(Mandatory = $true)] [string]$GraphUrl
    )
    Try {
        # Graph API URLs
        $LoginUrl = "https://login.microsoftonline.com"
        $ResourceUrl = "https://graph.microsoft.com"

        # Compose REST request
        $Body = @{
            grant_type    = "client_credentials"
            resource      = $ResourceUrl
            client_id     = $ClientID
            client_secret = $ClientSecret
        }
        $OAuth = Invoke-RestMethod -Method Post -Uri "$LoginUrl/$TenantName/oauth2/token?api-version=1.0" -Body $Body

        # Perform REST call
        $HeaderParams = @{ 'Authorization' = "$($OAuth.token_type) $($OAuth.access_token)" }
        $Result = Invoke-RestMethod -Headers $HeaderParams -Uri $GraphUrl

        # Format Microsoft Graph Output
        $Result.value | ConvertTo-Csv -NoTypeInformation
    }
    Catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Parameters
$ClientID = "98ax2c6d2-264c-424e-b911-c33x547de5211"
$ClientSecret = Read-Host -Prompt "Enter Client Secret" -AsSecureString | ConvertFrom-SecureString
$TenantName = "crescentintranet.onmicrosoft.com"
$GraphUrl = "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageDetail(period='D30')"

# Call the function to get usage data
$UsageData = Get-UsageReport -ClientID $ClientID -ClientSecret $ClientSecret -TenantName $TenantName -GraphUrl $GraphUrl
$UsageData | Out-File "C:\Temp\siteusage.csv" -Encoding utf8

# Read more: https://www.sharepointdiary.com/2019/11/sharepoint-online-usage-reports-using-graph-api-powershell.html#ixzz79jA0zqn0