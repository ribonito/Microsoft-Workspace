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
    Connect-MgGraph -Scopes "Policy.Read.All","Policy.ReadWrite.ConditionalAccess","Application.Read.All","Group.Read.All" -NoWelcome

    # Get tenant details
    $Uri = "beta/organization?`$select=id,displayname"
    $Org = $(Invoke-MgGraphRequest -Uri $Uri).Value

    $TimeStamp = $ts = Get-Date -f "yyyyMMddHHmm"
    $Path = "$Path\$(($Org.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_')_$($Org.id)_$TimeStamp"

    [PSCustomObject]@{
        "Action" = "Backup"
        "Type"   = "Intune Config Management"
        "Name"   = "IntuneBackupAndRestore - Start Intune Backup Config and Assignments"
        "Path"   = $Path
    }

	Invoke-SRIntuneBackupAppProtectionPolicy -Path $Path
	Invoke-SRIntuneBackupAppProtectionPolicyAssignment -Path $Path
	Invoke-SRIntuneBackupAssignmentFilter -Path $Path
	Invoke-SRIntuneBackupAutopilotDeploymentProfile -Path $Path
	Invoke-SRIntuneBackupAutopilotDeploymentProfileAssignments -Path $Path
	Invoke-SRIntuneBackupClientApp -Path $Path
	Invoke-SRIntuneBackupClientAppAssignment -Path $Path
	Invoke-SRIntuneBackupComplianceNotificationMessageTemplates -Path $Path
	Invoke-SRIntuneBackupConditionalAccessPolicy -Path $Path
	Invoke-SRIntuneBackupConfigurationPolicy -Path $Path
	Invoke-SRIntuneBackupConfigurationPolicyAssignment -Path $Path
	Invoke-SRIntuneBackupDeviceCompliancePolicy -Path $Path
	Invoke-SRIntuneBackupDeviceCompliancePolicyAssignment -Path $Path
	Invoke-SRIntuneBackupDeviceConfiguration -Path $Path
	Invoke-SRIntuneBackupDeviceConfigurationAssignment -Path $Path
	Invoke-SRIntuneBackupDeviceEnrollmentConfig -Path $Path
	Invoke-SRIntuneBackupDeviceEnrollmentConfigAssignments -Path $Path
	Invoke-SRIntuneBackupDeviceHealthScript -Path $Path
	Invoke-SRIntuneBackupDeviceHealthScriptAssignment -Path $Path
	Invoke-SRIntuneBackupDeviceManagementIntent -Path $Path
	Invoke-SRIntuneBackupDeviceManagementScript -Path $Path
	Invoke-SRIntuneBackupDeviceManagementScriptAssignment -Path $Path
	Invoke-SRIntuneBackupGroupPolicyConfiguration -Path $Path
	Invoke-SRIntuneBackupGroupPolicyConfigurationAssignment -Path $Path
	Invoke-SRIntuneBackupGroups -Path $Path
	Invoke-SRIntuneBackupScopeTag -Path $Path
	Invoke-SRIntuneBackupWindowsDriverUpdateProfile -Path $Path
	Invoke-SRIntuneBackupWindowsDriverUpdateProfileAssignments -Path $Path
	Invoke-SRIntuneBackupWindowsFeatureUpdateProfile -Path $Path
	Invoke-SRIntuneBackupWindowsFeatureUpdateProfileAssignments -Path $Path
	Invoke-SRIntuneBackupWindowsQualityUpdateProfile -Path $Path
	Invoke-SRIntuneBackupWindowsQualityUpdateProfileAssignments -Path $Path

}
