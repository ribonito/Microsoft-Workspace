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

    #Import-Module Microsoft.Graph.Intune
    #Connect-MSGraph | Out-Null
    Connect-MgGraph -Scopes "Policy.Read.All","Policy.Read.ConditionalAccess","Application.Read.All","Group.Read.All" -NoWelcome

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
	Invoke-SRIntuneBackupAppProtectionPolicy -Path $Path -ApiVersion v1.0
	Invoke-SRIntuneBackupAppProtectionPolicyAssignment -Path $Path -ApiVersion v1.0
	Invoke-SRIntuneBackupAssignmentFilter -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupAutopilotDeploymentProfile -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupAutopilotDeploymentProfileAssignments -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupBrandingProfiles -Path $Path -ApiVersion beta
    Invoke-SRIntuneBackupBrandingProfilesAssignments -Path $Path -ApiVersion beta
    Invoke-SRIntuneBackupClientApp -Path $Path -ApiVersion v1.0
	Invoke-SRIntuneBackupClientAppAssignment -Path $Path
	Invoke-SRIntuneBackupComplianceNotificationMessageTemplates -Path $Path -ApiVersion v1.0
	Invoke-SRIntuneBackupConditionalAccessPolicy -Path $Path -ApiVersion v1.0
	Invoke-SRIntuneBackupConfigurationPolicy -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupConfigurationPolicyAssignment -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceCompliancePolicy -Path $Path -ApiVersion v1.0
	Invoke-SRIntuneBackupDeviceCompliancePolicyAssignment -Path $Path -ApiVersion v1.0
	Invoke-SRIntuneBackupDeviceConfiguration -Path $Path -ApiVersion v1.0
	Invoke-SRIntuneBackupDeviceConfigurationAssignment -Path $Path -ApiVersion v1.0
	Invoke-SRIntuneBackupDeviceEnrollmentConfig -Path $Path -ApiVersion v1.0
	Invoke-SRIntuneBackupDeviceEnrollmentConfigAssignments -Path $Path -ApiVersion v1.0
	Invoke-SRIntuneBackupDeviceHealthScript -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceHealthScriptAssignment -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceManagementIntent -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceManagementScript -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupDeviceManagementScriptAssignment -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupGroupPolicyConfiguration -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupGroupPolicyConfigurationAssignment -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupGroups -Path $Path -ApiVersion v1.0
	Invoke-SRIntuneBackupScopeTag -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupWindowsDriverUpdateProfile -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupWindowsDriverUpdateProfileAssignments -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupWindowsFeatureUpdateProfile -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupWindowsFeatureUpdateProfileAssignments -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupWindowsQualityUpdateProfile -Path $Path -ApiVersion beta
	Invoke-SRIntuneBackupWindowsQualityUpdateProfileAssignments -Path $Path -ApiVersion beta

}
