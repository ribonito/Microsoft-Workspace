function Start-SRIntuneRestoreConfig() {
    <#
    .SYNOPSIS
    Restore Intune Configuration
    
    .DESCRIPTION
    Restore Intune Configuration
    
    .PARAMETER Path
    Path where backup (JSON) files are located.
    
    .EXAMPLE
    Start-SRIntuneRestore -Path C:\temp
    
    .NOTES
    Requires the MSGraphFunctions PowerShell Module

    Connect to MSGraph first, using the 'Connect-Graph' cmdlet.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [switch]$Assigments
    )


    #Import-Module Microsoft.Graph.Intune
    #Connect-MSGraph | Out-Null
    Connect-MgGraph -Scopes DeviceManagementManagedDevices.PrivilegedOperations.All,DeviceManagementManagedDevices.ReadWrite.All,DeviceManagementRBAC.ReadWrite.All,DeviceManagementApps.ReadWrite.All,DeviceManagementConfiguration.ReadWrite.All,DeviceManagementServiceConfig.ReadWrite.All,Group.ReadWrite.All,GroupMember.ReadWrite.All,Directory.Read.All -NoWelcome

    # Get source and target tenant details
    $Uri = "v1.0/organization?`$select=id,displayname"
    $TargetTenant = $(Invoke-MgGraphRequest -Uri $Uri).Value
    $SourceTenant = Import-SRTenantInfoFromCSV -Path "$Path"
    $SourceTenantid = $($SourceTenant.Values[0])
    If($SourceTenantid -eq $($TargetTenant.id)) {
        $SameTenant = $true
    } else {
        $SameTenant = $false
    }

    [PSCustomObject]@{
        "Action" = "Restore"
        "Type"   = "Intune Backup and Restore Action"
        "Name"   = "IntuneBackupAndRestore - Start Intune Restore Config"
        "Path"   = $Path
        "Restore assignments" = $Assigments
        "Same tenant" = $SameTenant
    }

    If (!($SameTenant)) {
        $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
        If ($Assigments) {
            $SourceGroups = Import-SRGroupsFromCSV -Path "$Path"
            $SourceFilters = Import-SRFiltersFromCSV -Path "$Path"
        }
    }

    Invoke-SRIntuneRestoreScopeTags -Path $Path
    Invoke-SRIntuneRestoreGroups -Path $Path
    Invoke-SRIntuneRestoreAssignmentFilter -Path $Path
    Invoke-SRIntuneRestoreNotificationTemplates

	Invoke-SRIntuneRestoreAppProtectionPolicy -Path $Path
	Invoke-SRIntuneRestoreAppProtectionPolicyAssignment -Path $Path
	Invoke-SRIntuneRestoreAutopilotDeploymentProfile -Path $Path
	Invoke-SRIntuneRestoreAutopilotDeploymentProfileAssignments -Path $Path
	Invoke-SRIntuneRestoreBrandingProfiles -Path $Path
	Invoke-SRIntuneRestoreBrandingProfilesAssignments -Path $Path
	Invoke-SRIntuneRestoreClientApps -Path $Path
	Invoke-SRIntuneRestoreClientAppAssignment -Path $Path
	Invoke-SRIntuneRestoreConditionalAccessPolicy -Path $Path
	Invoke-SRIntuneRestoreDeviceCompliancePolicy -Path $Path
	Invoke-SRIntuneRestoreDeviceCompliancePolicyAssignment -Path $Path
	Invoke-SRIntuneRestoreDeviceConfiguration -Path $Path
	Invoke-SRIntuneRestoreDeviceConfigurationAssignment -Path $Path
	Invoke-SRIntuneRestoreDeviceEnrollmentConfig -Path $Path
	Invoke-SRIntuneRestoreDeviceEnrollmentConfigAssignment -Path $Path
	Invoke-SRIntuneRestoreDeviceHealthScript -Path $Path
	Invoke-SRIntuneRestoreDeviceHealthScriptAssignment -Path $Path
	Invoke-SRIntuneRestoreDeviceManagementIntent -Path $Path
	Invoke-SRIntuneRestoreDeviceManagementIntentAssignment -Path $Path
	Invoke-SRIntuneRestoreDeviceManagementScript -Path $Path
	Invoke-SRIntuneRestoreDeviceManagementScriptAssignment -Path $Path
	Invoke-SRIntuneRestoreGroupPolicyConfiguration -Path $Path
	Invoke-SRIntuneRestoreGroupPolicyConfigurationAssignment -Path $Path
	Invoke-SRIntuneRestoreWindowsDriverUpdateProfile -Path $Path
	Invoke-SRIntuneRestoreWindowsDriverUpdateProfileAssignment -Path $Path
	Invoke-SRIntuneRestoreWindowsFeatureUpdateProfile -Path $Path
	Invoke-SRIntuneRestoreWindowsFeatureUpdateProfileAssignment -Path $Path
	Invoke-SRIntuneRestoreWindowsQualityUpdateProfile -Path $Path
	Invoke-SRIntuneRestoreWindowsQualityUpdateProfileAssignment -Path $Path
}

#Start-SRIntuneRestoreConfig -Path C:\temp\intunerestore -Assigments