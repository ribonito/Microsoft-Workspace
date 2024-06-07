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
    Requires the Microsoft.Graph.Intune PowerShell Module
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [switch]$Assigments
    )


    Import-Module Microsoft.Graph.Intune
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
        $SourceApps = Import-SRAppsFromCSV -Path "$Path"
        If ($Assigments) {
            $SourceGroups = Import-SRGroupsFromCSV -Path "$Path"
            $SourceFilters = Import-SRFiltersFromCSV -Path "$Path"
        }

        $Uri = "v1.0/organization/organization/$($TargetTenant.id)?`$select=mobiledevicemanagementauthority"
        $mdmAuthority = $(Invoke-MgGraphRequest -Uri $Uri).mobileDeviceManagementAuthority

        if($mdmAuthority -ne "intune"){
            $Uri = "v1.0/organization/organization/$($TargetTenant.id)/setMobileDeviceManagementAuthority"
            $null = Invoke-MgGraphRequest -Uri $Uri -Method POST -ErrorAction Stop
        }
    }

    Invoke-SRIntuneRestoreScopeTags -Path $Path
    Invoke-SRIntuneRestoreGroups -Path $Path
    Invoke-SRIntuneRestoreAssignmentFilter -Path $Path
    Invoke-SRIntuneRestoreNotificationTemplates -Path $Path
	Invoke-SRIntuneRestoreClientApps -Path $Path

	Invoke-SRIntuneRestoreAndroidDeviceEnrollmentProfile -Path $Path
    Invoke-SRIntuneRestoreAppProtectionPolicy -Path $Path
	Invoke-SRIntuneRestoreAutopilotDeploymentProfile -Path $Path
	Invoke-SRIntuneRestoreBrandingProfiles -Path $Path
	Invoke-SRIntuneRestoreAppConfigurationPolicy -Path $Path
	Invoke-SRIntuneRestoreConditionalAccessPolicy -Path $Path
	Invoke-SRIntuneRestoreDeviceCompliancePolicy -Path $Path
	Invoke-SRIntuneRestoreDeviceConfiguration -Path $Path
	Invoke-SRIntuneRestoreDeviceEnrollmentConfig -Path $Path
	Invoke-SRIntuneRestoreDeviceHealthScript -Path $Path
	Invoke-SRIntuneRestoreDeviceManagementIntent -Path $Path
	Invoke-SRIntuneRestoreDeviceManagementScript -Path $Path
	Invoke-SRIntuneRestoreGroupPolicyConfiguration -Path $Path
	Invoke-SRIntuneRestoreWindowsDriverUpdateProfile -Path $Path
	Invoke-SRIntuneRestoreWindowsFeatureUpdateProfile -Path $Path
	Invoke-SRIntuneRestoreWindowsQualityUpdateProfile -Path $Path

    if ($Assigments) {
    	Invoke-SRIntuneRestoreAppProtectionPolicyAssignment -Path $Path
	    Invoke-SRIntuneRestoreAutopilotDeploymentProfileAssignment -Path $Path
    	Invoke-SRIntuneRestoreBrandingProfilesAssignments -Path $Path
	    Invoke-SRIntuneRestoreClientAppAssignment -Path $Path
        Invoke-SRIntuneRestoreAppConfigurationPolicyAssignment -Path $Path
    	Invoke-SRIntuneRestoreDeviceCompliancePolicyAssignment -Path $Path
	    Invoke-SRIntuneRestoreDeviceConfigurationAssignment -Path $Path
    	Invoke-SRIntuneRestoreDeviceEnrollmentConfigAssignment -Path $Path
	    Invoke-SRIntuneRestoreDeviceHealthScriptAssignment -Path $Path
    	Invoke-SRIntuneRestoreDeviceManagementIntentAssignments -Path $Path
    	Invoke-SRIntuneRestoreDeviceManagementScriptAssignment -Path $Path
	    Invoke-SRIntuneRestoreGroupPolicyConfigurationAssignment -Path $Path
    	Invoke-SRIntuneRestoreWindowsDriverUpdateProfileAssignments -Path $Path
	    Invoke-SRIntuneRestoreWindowsFeatureUpdateProfileAssignments -Path $Path
	    Invoke-SRIntuneRestoreWindowsQualityUpdateProfileAssignments -Path $Path
    }
}

#Start-SRIntuneRestoreConfig -Path C:\temp\intunerestore -Assigments