
# =====================================================================
# INTUNE FULL TENANT JSON EXPORT
# =====================================================================

$ExportPath = "C:\Temp\IntuneFullExport"

New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null

$Folders = @(
    "Users",
    "Devices",
    "Groups",
    "ConfigurationPolicies",
    "CompliancePolicies",
    "EndpointSecurity",
    "DeviceConfigurations",
    "Scripts",
    "Remediations",
    "Autopilot",
    "Applications",
    "AppConfigurationPolicies",
    "AppProtectionPolicies",
    "EnrollmentProfiles",
    "ScopeTags"
)

foreach ($Folder in $Folders)
{
    New-Item `
        -Path "$ExportPath\$Folder" `
        -ItemType Directory `
        -Force | Out-Null
}

# =====================================================================
# GRAPH CONNECTION
# =====================================================================

Connect-MgGraph -Scopes `
"DeviceManagementConfiguration.Read.All",`
"DeviceManagementManagedDevices.Read.All",`
"DeviceManagementApps.Read.All",`
"DeviceManagementServiceConfig.Read.All",`
"DeviceManagementRBAC.Read.All",`
"Group.Read.All",`
"User.Read.All"

Write-Host "Connected to Graph" -ForegroundColor Green



# =====================================================================
# CONFIGURATION POLICIES
# =====================================================================

Write-Host "Exporting Configuration Policies..."

$Policies = Get-MgBetaDeviceManagementConfigurationPolicy -All

foreach ($Policy in $Policies)
{
    $SafeName = ($Policy.Name -replace '[\\/:*?"<>|]', '_')

    Write-Host "Policy: $SafeName"

    $PolicyObject = Invoke-MgGraphRequest `
        -Method GET `
        -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($Policy.Id)"

    $PolicyObject |
    ConvertTo-Json -Depth 100 |
    Out-File `
        "$ExportPath\ConfigurationPolicies\$SafeName-Policy.json" `
        -Encoding UTF8

    $Settings = Invoke-MgGraphRequest `
        -Method GET `
        -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($Policy.Id)/settings"

    $Settings |
    ConvertTo-Json -Depth 100 |
    Out-File `
        "$ExportPath\ConfigurationPolicies\$SafeName-Settings.json" `
        -Encoding UTF8

    $Assignments = Invoke-MgGraphRequest `
        -Method GET `
        -Uri "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies/$($Policy.Id)/assignments"

    $Assignments |
    ConvertTo-Json -Depth 100 |
    Out-File `
        "$ExportPath\ConfigurationPolicies\$SafeName-Assignments.json" `
        -Encoding UTF8
}

# =====================================================================
# COMPLIANCE POLICIES
# =====================================================================

Write-Host "Exporting Compliance Policies..."

Get-MgBetaDeviceManagementDeviceCompliancePolicy -All |
ForEach-Object {

    $SafeName = ($_.DisplayName -replace '[\\/:*?"<>|]', '_')

    $Policy = Invoke-MgGraphRequest `
        -Method GET `
        -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies/$($_.Id)"

    $Policy |
    ConvertTo-Json -Depth 100 |
    Out-File `
        "$ExportPath\CompliancePolicies\$SafeName.json" `
        -Encoding UTF8
}

# =====================================================================
# ENDPOINT SECURITY
# =====================================================================

Write-Host "Exporting Endpoint Security Policies..."

Get-MgBetaDeviceManagementIntent -All |
ForEach-Object {

    $SafeName = ($_.DisplayName -replace '[\\/:*?"<>|]', '_')

    $Intent = Invoke-MgGraphRequest `
        -Method GET `
        -Uri "https://graph.microsoft.com/beta/deviceManagement/intents/$($_.Id)"

    $Intent |
    ConvertTo-Json -Depth 100 |
    Out-File `
        "$ExportPath\EndpointSecurity\$SafeName.json" `
        -Encoding UTF8
}

# =====================================================================
# DEVICE CONFIGURATION PROFILES
# =====================================================================

Write-Host "Exporting Device Configuration Profiles..."

Get-MgBetaDeviceManagementDeviceConfiguration -All |
ForEach-Object {

    $SafeName = ($_.DisplayName -replace '[\\/:*?"<>|]', '_')

    $_ |
    ConvertTo-Json -Depth 100 |
    Out-File `
        "$ExportPath\DeviceConfigurations\$SafeName.json" `
        -Encoding UTF8
}

# =====================================================================
# SCRIPTS
# =====================================================================

Write-Host "Exporting PowerShell Scripts..."

Get-MgBetaDeviceManagementDeviceManagementScript -All |
ForEach-Object {

    $SafeName = ($_.DisplayName -replace '[\\/:*?"<>|]', '_')

    $_ |
    ConvertTo-Json -Depth 100 |
    Out-File `
        "$ExportPath\Scripts\$SafeName.json" `
        -Encoding UTF8
}

# =====================================================================
# REMEDIATIONS
# =====================================================================

Write-Host "Exporting Remediation Scripts..."

Get-MgBetaDeviceManagementDeviceHealthScript -All |
ForEach-Object {

    $SafeName = ($_.DisplayName -replace '[\\/:*?"<>|]', '_')

    $_ |
    ConvertTo-Json -Depth 100 |
    Out-File `
        "$ExportPath\Remediations\$SafeName.json" `
        -Encoding UTF8
}

# =====================================================================
# AUTOPILOT
# =====================================================================

Write-Host "Exporting Autopilot Profiles..."

Get-MgBetaDeviceManagementWindowsAutopilotDeploymentProfile -All |
ForEach-Object {

    $SafeName = ($_.DisplayName -replace '[\\/:*?"<>|]', '_')

    $_ |
    ConvertTo-Json -Depth 100 |
    Out-File `
        "$ExportPath\Autopilot\$SafeName.json" `
        -Encoding UTF8
}


# =====================================================================
# APP CONFIGURATION POLICIES
# =====================================================================

Write-Host "Exporting App Configuration Policies..."

Get-MgBetaDeviceAppManagementMobileAppConfiguration -All |
ForEach-Object {

    $SafeName = ($_.DisplayName -replace '[\\/:*?"<>|]', '_')

    $_ |
    ConvertTo-Json -Depth 100 |
    Out-File `
        "$ExportPath\AppConfigurationPolicies\$SafeName.json" `
        -Encoding UTF8
}

# =====================================================================
# APP PROTECTION POLICIES
# =====================================================================

Write-Host "Exporting App Protection Policies..."

Get-MgBetaDeviceAppManagementManagedAppPolicy -All |
ForEach-Object {

    $SafeName = ($_.DisplayName -replace '[\\/:*?"<>|]', '_')

    $_ |
    ConvertTo-Json -Depth 100 |
    Out-File `
        "$ExportPath\AppProtectionPolicies\$SafeName.json" `
        -Encoding UTF8
}

# =====================================================================
# ENROLLMENT PROFILES
# =====================================================================

Write-Host "Exporting Enrollment Profiles..."

$EnrollmentProfiles = Invoke-MgGraphRequest `
-Method GET `
-Uri "https://graph.microsoft.com/beta/deviceManagement/deviceEnrollmentConfigurations"

$EnrollmentProfiles |
ConvertTo-Json -Depth 100 |
Out-File `
"$ExportPath\EnrollmentProfiles\EnrollmentProfiles.json" `
-Encoding UTF8

# =====================================================================
# SCOPE TAGS
# =====================================================================

Write-Host "Exporting Scope Tags..."

$ScopeTags = Invoke-MgGraphRequest `
-Method GET `
-Uri "https://graph.microsoft.com/beta/deviceManagement/roleScopeTags"

$ScopeTags |
ConvertTo-Json -Depth 100 |
Out-File `
"$ExportPath\ScopeTags\ScopeTags.json" `
-Encoding UTF8

# =====================================================================
# SUMMARY
# =====================================================================

Write-Host ""
Write-Host "===================================" -ForegroundColor Green
Write-Host " INTUNE FULL EXPORT COMPLETED" -ForegroundColor Green
Write-Host " EXPORT PATH: $ExportPath" -ForegroundColor Green
Write-Host "===================================" -ForegroundColor Green
Write-Host ""