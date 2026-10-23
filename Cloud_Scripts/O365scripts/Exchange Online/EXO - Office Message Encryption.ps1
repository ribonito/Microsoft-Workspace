<#
.SYNOPSIS
    Manages and configures Office 365 Message Encryption (OME) and Azure Information Protection (AIP/IRM).

.DESCRIPTION
    Validates, configures, and enables Office 365 Message Encryption (OME) and Information Rights
    Management (IRM) in Exchange Online. Tests connectivity to AIPService, verifies RMS templates,
    sets licensing distribution endpoints, enables simplified OWA client access (Protect button,
    Encrypt Only, Do Not Forward), and executes diagnostics via Test-IRMConfiguration.

.NOTES
    Requires the AIPService and ExchangeOnlineManagement PowerShell modules.
    Modern authentication with MFA is supported.
    Ensure $AdminUpn is defined prior to execution.

.LINK
    https://learn.microsoft.com/microsoft-365/compliance/ome-faq
    https://learn.microsoft.com/powershell/module/exchange/set-irmconfiguration
    https://learn.microsoft.com/powershell/module/exchange/get-irmconfiguration
    https://learn.microsoft.com/powershell/module/aipservice/enable-aipservice
#>

# Step 1: Import required modules and authenticate
Import-Module AIPService -ErrorAction SilentlyContinue
Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue

$AdminUpn = ""
if ([string]::IsNullOrWhiteSpace($AdminUpn)) {
    Connect-ExchangeOnline
    Connect-AipService
} else {
    Connect-ExchangeOnline -UserPrincipalName $AdminUpn
    Connect-AipService
}

# Step 2: Validate installed module versions
Get-Module AIPService, ExchangeOnlineManagement -ListAvailable |
    Select-Object Name, Version, Path |
    Format-Table -AutoSize

# Step 3: Retrieve current AIP and IRM configurations
$AipService = Get-AipService
$AipConfig  = Get-AipServiceConfiguration
$IrmConfig  = Get-IRMConfiguration

Write-Host "=== Current Status ===" -ForegroundColor Cyan
Write-Host "AIP Service Status: " -NoNewline
if ($AipService -eq "Disabled") {
    Write-Host "Disabled" -ForegroundColor Red
} else {
    Write-Host "Enabled" -ForegroundColor Green
}

Write-Host "`nAIP Configuration:" -ForegroundColor Yellow
$AipConfig | Format-List LicensingIntranetDistributionPointUrl, LicensingExtranetDistributionPointUrl

Write-Host "IRM Configuration:" -ForegroundColor Yellow
$IrmConfig | Format-List AzureRMSLicensingEnabled, InternalLicensingEnabled, SimplifiedClientAccessEnabled, LicensingLocation

# Step 4: Enable AIP service if currently disabled
if ($AipService -eq "Disabled") {
    Write-Host "AIP Service is disabled. Enabling AIP Service..." -ForegroundColor Yellow
    Enable-AipService
}

# Step 5: Configure IRM Licensing Location
$LicenseUrl = $AipConfig.LicensingIntranetDistributionPointUrl
$List = [System.Collections.Generic.List[string]]::new()
if ($IrmConfig.LicensingLocation) {
    foreach ($loc in $IrmConfig.LicensingLocation) {
        $List.Add($loc)
    }
}

if ($LicenseUrl -and -not $List.Contains($LicenseUrl)) {
    Write-Host "Adding Licensing Distribution Point URL ($LicenseUrl) to IRM LicensingLocation..." -ForegroundColor Yellow
    $List.Add($LicenseUrl)
    Set-IRMConfiguration -LicensingLocation $List
}

# Step 6: Enable Azure RMS and Internal Licensing
Write-Host "Enabling Azure RMS licensing and internal licensing in IRM..." -ForegroundColor Yellow
Set-IRMConfiguration -AzureRMSLicensingEnabled $true -InternalLicensingEnabled $true

# Step 7: Configure OWA simplified client access (Protect button, Encrypt-Only, Do Not Forward)
Write-Host "Configuring OWA simplified client access and PDF encryption..." -ForegroundColor Yellow
Set-IRMConfiguration -SimplifiedClientAccessEnabled $true `
                     -SimplifiedClientAccessEncryptOnlyDisabled $false `
                     -SimplifiedClientAccessDoNotForwardDisabled $false `
                     -EnablePdfEncryption $true `
                     -SearchEnabled $true

# Step 8: Validate configuration and test IRM with sample sender
Write-Host "`n=== Final Validation ===" -ForegroundColor Cyan
Get-IRMConfiguration | Format-List AzureRMSLicensingEnabled, InternalLicensingEnabled, SimplifiedClientAccessEnabled
Get-RMSTemplate | Format-Table Name, Id, Type -AutoSize

if (-not [string]::IsNullOrWhiteSpace($AdminUpn)) {
    Write-Host "Running IRM configuration test for sender $AdminUpn..." -ForegroundColor Cyan
    Test-IRMConfiguration -Sender $AdminUpn
}
