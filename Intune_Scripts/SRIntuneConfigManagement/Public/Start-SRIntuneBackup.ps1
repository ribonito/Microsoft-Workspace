function Start-SRIntuneBackup() {
    <#
    .SYNOPSIS
    Backup Intune Configuration

    .DESCRIPTION
    Backup Intune Configuration

    .PARAMETER Path
    Path to store backup (JSON) files.

    .EXAMPLE
    Start-SRIntuneBackup -Path C:\temp

    .NOTES
    Requires the MSGraphFunctions PowerShell Module

    Connect to MSGraph first, using the 'Connect-Graph' cmdlet.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Connect-MgGraph -Scopes Policy.Read.All,Policy.Read.ConditionalAccess,Application.Read.All,Group.Read.All,DeviceManagementConfiguration.Read.All,DeviceManagementApps.Read.All,DeviceManagementRBAC.Read.All,DeviceManagementServiceConfig.Read.All -NoWelcome

    # Get tenant details
    $Uri = "v1.0/organization?`$select=id,displayname"
    $Org = $(Invoke-MgGraphRequest -Uri $Uri).Value

    $TimeStamp = $ts = Get-Date -f "yyyyMMddHHmm"
    $Path = "$Path\$(($Org.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_')_$($Org.id)_$TimeStamp"

    [PSCustomObject]@{
        "Action" = "Backup"
        "Type"   = "Intune Config Management"
        "Name"   = "IntuneBackupAndRestore - Start Intune Backup Config and Assignments"
        "Path"   = $Path
    }

    Invoke-SRIntuneBackupTenantInfo -Path $Path -ApiVersion v1.0
	Invoke-SRIntuneBackupAndroidDeviceEnrollmentProfile -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupAppProtectionPolicy -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupAppProtectionPolicyAssignment -Path $Path -ApiVersion beta
    Invoke-SRIntuneBackupAppConfigurationPolicy -Path $Path -ApiVersion beta
    Invoke-SRIntuneBackupAppConfigurationPolicyAssignment -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupAssignmentFilter -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupAutopilotDeploymentProfile -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupAutopilotDeploymentProfileAssignments -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupBrandingProfiles -Path $Path -ApiVersion beta
    Invoke-SRIntuneBackupBrandingProfilesAssignments -Path $Path -ApiVersion beta
    Invoke-SRIntuneBackupClientApp -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupClientAppAssignment -Path $Path
	Invoke-SRIntuneBackupNotificationTemplates -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupConditionalAccessPolicy -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupConfigurationPolicy -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupConfigurationPolicyAssignment -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceCompliancePolicy -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceCompliancePolicyAssignment -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceConfiguration -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceConfigurationAssignment -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceEnrollmentConfig -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceEnrollmentConfigAssignments -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceHealthScript -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceHealthScriptAssignment -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceManagementIntent -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceManagementIntentAssignments -Path $Path -ApiVersion beta
    Invoke-SRIntuneBackupDeviceManagementScript -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceManagementScriptAssignment -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupGroupPolicyConfiguration -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupGroupPolicyConfigurationAssignment -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupGroups -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupScopeTag -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupWindowsDriverUpdateProfile -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupWindowsDriverUpdateProfileAssignments -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupWindowsFeatureUpdateProfile -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupWindowsFeatureUpdateProfileAssignments -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupWindowsQualityUpdateProfile -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupWindowsQualityUpdateProfileAssignments -Path $Path -ApiVersion beta
}
