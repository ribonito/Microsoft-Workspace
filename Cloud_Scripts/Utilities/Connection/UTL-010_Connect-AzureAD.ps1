<#
.SYNOPSIS
    UTL-010 | Connect to Entra ID / Azure Active Directory v2.

.DESCRIPTION
    PowerShell utility script that connects to Azure Active Directory v2. Includes administrative commands 
    to install, update, and remove both AzureAD and AzureADPreview modules, as well as signing in with or 
    without Multi-Factor Authentication (MFA).

.PRODUCT
    Azure Active Directory / Entra ID

.ORIGINAL_AUTHOR
    O365scripts Contributors (O365ConnectAzureActiveDirectory classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/Connection/O365ConnectAzureActiveDirectory.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-010 classification)

.VERSION
    1.0

.NOTES
    Name: UTL-010_Connect-AzureAD.ps1
    Requires: AzureAD or AzureADPreview module.

.PARAMETER AdminUpn
    The User Principal Name (UPN) of the Administrator account.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$AdminUpn = ""
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Install and connect to Azure AD
Install-Module AzureAD -AllowClobber -Force -Confirm:$false
Import-Module AzureAD
Connect-AzureAD -AccountId $AdminUpn

# Connect to Azure AD without MFA and use stored credentials
# $Creds = Get-Credential -UserName $AdminUpn -Message "Login:"
# Connect-AzureAD -AccountId $AdminUpn -Credential $Creds

# Azure AD/Preview module installed?
Get-Module AzureAD* -ListAvailable | Select-Object Name, Version

# Install module as non-admin user?
# Install-Module AzureAD -Scope "CurrentUser" -AllowClobber -Force -Confirm:$false
# Install-Module AzureADPreview -Scope "CurrentUser" -AllowClobber -Force -Confirm:$false

# Update Azure AD/Preview module?
# Update-Module AzureAD -Confirm:$false -Force
# Update-Module AzureADPreview -Confirm:$false -Force

# Remove Azure AD/Preview module?
# Uninstall-Module AzureAD -AllVersions -Confirm:$false -Force
# Uninstall-Module AzureADPreview -AllVersions -Confirm:$false -Force

# Close session?
# $Creds = $null; Disconnect-AzureAD
#endregion
