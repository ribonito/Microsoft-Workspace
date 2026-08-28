<#
.SYNOPSIS
    M365-016 | Provision Microsoft 365 / Office 365 Group via Azure Function.

.DESCRIPTION
    PowerShell script designed to run in an Azure Function (HTTP trigger) that checks for the existence 
    of a Microsoft 365 Group and provisions a new one if not found. It also assigns a user as both 
    owner and member using Microsoft Graph API client credentials.

.PRODUCT
    Microsoft 365 / Entra ID

.ORIGINAL_AUTHOR
    Christoph Wilfing, Toni Pohl, Martina Grom - atwork.at

.MAINTAINER
    Josep Canas - M365 Solutions Architect (M365-016 classification)

.VERSION
    1.0

.NOTES
    Name: M365-016_Provision-Group-Azure-Function.ps1
    Requires: Azure Function runtime and Microsoft Graph API Application Permissions (Group.ReadWrite.All, User.Read.All).
#>

#region ── Main Program ───────────────────────────────────────────────────────
$requestBody = Get-Content $req -Raw | ConvertFrom-Json
$GroupName = $requestBody.GroupName
$upn = $requestBody.upn

# Make email address safe...
$EMail = $GroupName.Trim().Replace(" ","-")

Write-Output "TenantID: $env:TenantID AppID: $env:AppID AppSecret: ***"
Write-Output "GroupName: $GroupName EMail: $EMail UPN: $upn"

function Initialize-Authorization {
    param
    (
      [string]
      $ResourceURL = 'https://graph.microsoft.com',
  
      [string]
      [parameter(Mandatory)]
      $TenantID,
      
      [string]
      [Parameter(Mandatory)]
      $ClientKey,
  
      [string]
      [Parameter(Mandatory)]
      $AppID
    )

    $Authority = "https://login.windows.net/$TenantID/oauth2/token"

    [Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
    $EncodedKey = [System.Web.HttpUtility]::UrlEncode($ClientKey)

    $body = "grant_type=client_credentials&client_id=$AppID&client_secret=$EncodedKey&resource=$ResourceUrl"

    # Request a Token from the graph api
    $result = Invoke-RestMethod -Method Post `
                        -Uri $Authority `
                        -ContentType 'application/x-www-form-urlencoded' `
                        -Body $body

    $script:APIHeader = @{'Authorization' = "Bearer $($result.access_token)" }
}

# Initialize Authorization
Initialize-Authorization -TenantID $env:TenantID -ClientKey $env:AppSecret -AppID $env:AppID

# Check if group is already existing
try {
    $uri = "https://graph.microsoft.com/v1.0/groups?`$filter=startswith(mail,'$EMail')"

    $result = Invoke-RestMethod -Method Get `
                            -Uri $uri `
                            -ContentType 'application/json' `
                            -Headers $script:APIHeader `

    # and save the generated Group ID
    $GroupID = $result.value.id
    Write-Output "GroupID: $GroupID"
} catch {
    Write-Output "ERROR! $_"
}

# If $GroupID is empty...
Write-Output "[$GroupID]"
if ([bool]$GroupID) 
{
    $msg = "EXISTING: $EMail, $GroupID"
}
else
{
    $msg = "CREATED: $EMail, $GroupID"

    # Create the Office 365 group
    $json = @"
{ "displayName": "$GroupName",
"mailenabled" : true,
"mailnickname":"$Email",
"securityenabled" : true,
"description": "$GroupName",
"groupTypes": ["Unified"]
}
"@

    try {
        $result = Invoke-RestMethod -Method Post `
                                -Uri "https://graph.microsoft.com/v1.0/groups" `
                                -ContentType 'application/json' `
                                -Headers $script:APIHeader `
                                -Body $json `
                                -ErrorAction Stop

        # and save the generated Group ID
        $GroupID = $result.id
        Write-Output "GroupID: $GroupID"
    } catch {
        Write-Output "ERROR! $_"
    }

    # Get the User ID
    try {
        $OwnerObject = Invoke-RestMethod -Method Get `
                                -Uri "https://graph.microsoft.com/v1.0/users/$upn" `
                                -ContentType 'application/json' `
                                -Headers $script:APIHeader `
                                -ErrorAction Stop
        Write-Output $OwnerObject.UserPrincipalName
    } catch {
        Write-Output "ERROR! $_"
    }

    # Add User as Owner
    $json = @"
{ "@odata.id": "https://graph.microsoft.com/v1.0/users/$($OwnerObject.id)" }
"@

    try {
        $result = Invoke-RestMethod -Method Post `
                                -Uri "https://graph.microsoft.com/v1.0/groups/$GroupID/owners/`$ref" `
                                -ContentType 'application/json' `
                                -Headers $script:APIHeader `
                                -Body $json `
                                -ErrorAction Stop
        Write-Output "Added owner: $GroupID"
    } catch {
        Write-Output "ERROR! $_"
    }

    # Add user as Member
    try {
        $result = Invoke-RestMethod -Method Post `
                                -Uri "https://graph.microsoft.com/v1.0/groups/$GroupID/members/`$ref" `
                                -ContentType 'application/json' `
                                -Headers $script:APIHeader `
                                -Body $json `
                                -ErrorAction Stop
        Write-Output "Added member: $GroupID"
    } catch {
        Write-Output "ERROR! $_"
    }
}

# return value
Out-File -Encoding Ascii -FilePath $res -inputObject $msg
Write-Output $msg
#endregion
