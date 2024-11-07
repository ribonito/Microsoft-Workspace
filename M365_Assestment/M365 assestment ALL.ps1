# M365 Assessment Script

# Import necessary modules
Import-Module Microsoft.Graph
Import-Module MicrosoftTeams
Import-Module ExchangeOnlineManagement

# Connect to Microsoft 365 services
Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Directory.Read.All"
Connect-MicrosoftTeams
Connect-ExchangeOnline

# Data Assessment
Write-Output "Performing Data Assessment..."
# Identity management, data protection, threat detection, and compliance checks
# Add your specific data assessment logic here

# Teams Information
Write-Output "Gathering Teams Information..."
$teams = Get-Team
$teamsInfo = $teams | ForEach-Object {
    [PSCustomObject]@{
        TeamName       = $_.DisplayName
        Nickname       = $_.MailNickname
        ObjectID       = $_.GroupId
        Owners         = (Get-TeamUser -GroupId $_.GroupId -Role Owner).User
        MemberCount    = (Get-TeamUser -GroupId $_.GroupId).Count
        Channels       = (Get-TeamChannel -GroupId $_.GroupId).DisplayName
        SharePointSite = $_.SharePointSiteUrl
        AccessType     = $_.Visibility
        GuestAccess    = $_.GuestSettings.AllowGuestCreateUpdateChannels
    }
}
$teamsInfo | Format-Table -AutoSize

# SharePoint Sites
Write-Output "Gathering SharePoint Sites Information..."
$sites = Get-SPOSite
$sitesInfo = $sites | ForEach-Object {
    [PSCustomObject]@{
        SiteID        = $_.Id
        URL           = $_.Url
        Owners        = (Get-SPOUser -Site $_.Url -Group "Owners").LoginName
        ActivityDate  = $_.LastContentModifiedDate
        FileCount     = $_.StorageUsageCurrent
        StorageUsage  = $_.StorageUsageCurrent
        Template      = $_.Template
    }
}
$sitesInfo | Format-Table -AutoSize

# User Mailboxes
Write-Output "Gathering User Mailboxes Information..."
$mailboxes = Get-Mailbox
$mailboxInfo = $mailboxes | ForEach-Object {
    [PSCustomObject]@{
        DisplayName   = $_.DisplayName
        MailboxType   = $_.RecipientTypeDetails
        TotalSize     = (Get-MailboxStatistics -Identity $_.UserPrincipalName).TotalItemSize
        ArchiveSize   = (Get-MailboxStatistics -Identity $_.UserPrincipalName -Archive).TotalItemSize
    }
}
$mailboxInfo | Format-Table -AutoSize

# Device Information
Write-Output "Gathering Device Information..."
$devices = Get-MgDevice
$deviceInfo = $devices | ForEach-Object {
    [PSCustomObject]@{
        DeviceID       = $_.Id
        OperatingSystem = $_.OperatingSystem
        JoinType       = $_.DeviceTrustType
        Owner          = $_.RegisteredOwners
        ComplianceStatus = $_.ComplianceState
        LastSignInDate = $_.ApproximateLastSignInDateTime
    }
}
$deviceInfo | Format-Table -AutoSize

# Licenses and Service Plans
Write-Output "Gathering Licenses and Service Plans Information..."
$licenses = Get-MgSubscribedSku
$licenseInfo = $licenses | ForEach-Object {
    [PSCustomObject]@{
        SkuPartNumber  = $_.SkuPartNumber
        ActiveUnits    = $_.ConsumedUnits
        ConsumedUnits  = $_.PrepaidUnits.Enabled
        RenewalDate    = $_.SubscriptionIds
    }
}
$licenseInfo | Format-Table -AutoSize

# Security Assessment
Write-Output "Performing Security Assessment..."
# Add your specific security assessment logic here

# Multi-Factor Authentication (MFA)
Write-Output "Checking Multi-Factor Authentication (MFA) status..."
$mfaStatus = Get-MsolUser -All | Select-Object UserPrincipalName, StrongAuthenticationRequirements
$mfaStatus | Format-Table -AutoSize

# Device Compliance
Write-Output "Verifying Device Compliance..."
# Add your specific device compliance logic here

# User Access
Write-Output "Reviewing User Access Permissions..."
# Add your specific user access review logic here

# Activity Monitoring
Write-Output "Implementing Activity Monitoring..."
# Add your specific activity monitoring logic here

# Security Policies
Write-Output "Establishing Security Policies..."
# Add your specific security policies logic here

# Incident Response
Write-Output "Developing Incident Response Plan..."
# Add your specific incident response plan logic here

# Governance Plan
Write-Output "Checking Governance Plan..."
# Add your specific governance plan logic here

# Data Management
Write-Output "Establishing Data Management Policies..."
# Add your specific data management policies logic here

# Access Control
Write-Output "Defining Access Control Roles..."
# Add your specific access control roles logic here

# Compliance
Write-Output "Ensuring Compliance with Regulations..."
# Add your specific compliance logic here

# Training and Awareness
Write-Output "Providing Training on Security Best Practices..."
# Add your specific training and awareness logic here

# Governance Framework
Write-Output "Developing Governance Framework..."
# Add your specific governance framework logic here

# Audit and Review
Write-Output "Conducting Regular Audits..."
# Add your specific audit and review logic here
# Function to perform security assessment
Function Invoke-SecurityAssessment {
    Write-Output "Performing Security Assessment..."
    # Add your specific security assessment logic here
}

# Function to verify device compliance
Function Verify-DeviceCompliance {
    Write-Output "Verifying Device Compliance..."
    # Add your specific device compliance logic here
}

# Function to review user access permissions
Function Review-UserAccess {
    Write-Output "Reviewing User Access Permissions..."
    # Add your specific user access review logic here
}

# Function to implement activity monitoring
Function Implement-ActivityMonitoring {
    Write-Output "Implementing Activity Monitoring..."
    # Add your specific activity monitoring logic here
}

# Function to establish security policies
Function Establish-SecurityPolicies {
    Write-Output "Establishing Security Policies..."
    # Add your specific security policies logic here
}

# Function to develop incident response plan
Function Develop-IncidentResponsePlan {
    Write-Output "Developing Incident Response Plan..."
    # Add your specific incident response plan logic here
}

# Function to check governance plan
Function Check-GovernancePlan {
    Write-Output "Checking Governance Plan..."
    # Add your specific governance plan logic here
}

# Function to establish data management policies
Function Establish-DataManagementPolicies {
    Write-Output "Establishing Data Management Policies..."
    # Add your specific data management policies logic here
}

# Function to define access control roles
Function Define-AccessControlRoles {
    Write-Output "Defining Access Control Roles..."
    # Add your specific access control roles logic here
}

# Function to ensure compliance with regulations
Function Ensure-Compliance {
    Write-Output "Ensuring Compliance with Regulations..."
    # Add your specific compliance logic here
}

# Function to provide training on security best practices
Function Provide-TrainingAndAwareness {
    Write-Output "Providing Training on Security Best Practices..."
    # Add your specific training and awareness logic here
}

# Function to develop governance framework
Function Develop-GovernanceFramework {
    Write-Output "Developing Governance Framework..."
    # Add your specific governance framework logic here
}

# Function to conduct regular audits
Function Conduct-RegularAudits {
    Write-Output "Conducting Regular Audits..."
    # Add your specific audit and review logic here
}
# Disconnect from Microsoft 365 services
Disconnect-MgGraph
Disconnect-MicrosoftTeams
Disconnect-ExchangeOnline

Write-Output "M365 Assessment Completed."
# Export function to Excel
Function Export-ToExcel {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        [Parameter(Mandatory=$true)]
        [PSObject[]]$Data
    )

    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $workbook = $excel.Workbooks.Add()
    $worksheet = $workbook.Worksheets.Item(1)

    $row = 1
    $col = 1

    # Add headers
    foreach ($property in $Data[0].PSObject.Properties) {
        $worksheet.Cells.Item($row, $col) = $property.Name
        $col++
    }

    $row++

    # Add data
    foreach ($item in $Data) {
        $col = 1
        foreach ($property in $item.PSObject.Properties) {
            $worksheet.Cells.Item($row, $col) = $property.Value
            $col++
        }
        $row++
    }

    $workbook.SaveAs($FilePath)
    $excel.Quit()
}

# Export gathered information to Excel files
Export-ToExcel -FilePath "TeamsInfo.xlsx" -Data $teamsInfo
Export-ToExcel -FilePath "SharePointSitesInfo.xlsx" -Data $sitesInfo
Export-ToExcel -FilePath "UserMailboxesInfo.xlsx" -Data $mailboxInfo
Export-ToExcel -FilePath "DeviceInfo.xlsx" -Data $deviceInfo
Export-ToExcel -FilePath "LicensesInfo.xlsx" -Data $licenseInfo
Export-ToExcel -FilePath "MFAStatus.xlsx" -Data $mfaStatus

# Device Compliance
Write-Output "Verifying Device Compliance..."
# Example logic for device compliance
$deviceCompliance = $deviceInfo | Where-Object { $_.ComplianceStatus -eq "Compliant" }
$deviceCompliance | Format-Table -AutoSize

# User Access
Write-Output "Reviewing User Access Permissions..."
# Example logic for user access review
$userAccess = Get-MgUser | Select-Object UserPrincipalName, AssignedPlans
$userAccess | Format-Table -AutoSize

# Activity Monitoring
Write-Output "Implementing Activity Monitoring..."
# Example logic for activity monitoring
$activityLogs = Get-MgAuditLogSignIn | Select-Object UserPrincipalName, CreatedDateTime, AppDisplayName, Status
$activityLogs | Format-Table -AutoSize

# Security Policies
Write-Output "Establishing Security Policies..."
# Example logic for security policies
$securityPolicies = Get-MgPolicy | Select-Object DisplayName, Description, IsEnabled
$securityPolicies | Format-Table -AutoSize

# Incident Response
Write-Output "Developing Incident Response Plan..."
# Example logic for incident response plan
$incidentResponsePlan = @(
    [PSCustomObject]@{ Step = "Identify"; Description = "Identify potential incidents" }
    [PSCustomObject]@{ Step = "Contain"; Description = "Contain the incident to prevent further damage" }
    [PSCustomObject]@{ Step = "Eradicate"; Description = "Eradicate the root cause of the incident" }
    [PSCustomObject]@{ Step = "Recover"; Description = "Recover systems to normal operation" }
    [PSCustomObject]@{ Step = "Review"; Description = "Review and learn from the incident" }
)
$incidentResponsePlan | Format-Table -AutoSize

# Governance Plan
Write-Output "Checking Governance Plan..."
# Example logic for governance plan
$governancePlan = Get-MgGovernancePolicy | Select-Object DisplayName, Description, State
$governancePlan | Format-Table -AutoSize

# Data Management
Write-Output "Establishing Data Management Policies..."
# Example logic for data management policies
$dataManagementPolicies = Get-MgDataPolicy | Select-Object DisplayName, Description, IsEnabled
$dataManagementPolicies | Format-Table -AutoSize

# Access Control
Write-Output "Defining Access Control Roles..."
# Example logic for access control roles
$accessControlRoles = Get-MgRoleDefinition | Select-Object DisplayName, Description, RolePermissions
$accessControlRoles | Format-Table -AutoSize

# Compliance
Write-Output "Ensuring Compliance with Regulations..."
# Example logic for compliance
$complianceStatus = Get-MgCompliancePolicy | Select-Object DisplayName, Description, IsEnabled
$complianceStatus | Format-Table -AutoSize

# Training and Awareness
Write-Output "Providing Training on Security Best Practices..."
# Example logic for training and awareness
$trainingSessions = @(
    [PSCustomObject]@{ Topic = "Phishing Awareness"; Date = "2023-01-15"; Attendees = 50 }
    [PSCustomObject]@{ Topic = "Password Management"; Date = "2023-02-20"; Attendees = 45 }
)
$trainingSessions | Format-Table -AutoSize

# Governance Framework
Write-Output "Developing Governance Framework..."
# Example logic for governance framework
$governanceFramework = @(
    [PSCustomObject]@{ Component = "Policy Management"; Description = "Manage and enforce policies" }
    [PSCustomObject]@{ Component = "Risk Management"; Description = "Identify and mitigate risks" }
)
$governanceFramework | Format-Table -AutoSize

# Audit and Review
Write-Output "Conducting Regular Audits..."
# Example logic for audit and review
$auditLogs = Get-MgAuditLog | Select-Object UserPrincipalName, Activity, CreatedDateTime
$auditLogs | Format-Table -AutoSize