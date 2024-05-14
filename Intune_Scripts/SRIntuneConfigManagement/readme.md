#Overview

Intune configuration automation is a toolset built using PowerShell scripts with the purpose to allow saving of various configuration objects in an Intune tenant as well as additional information required for restoring the configuration in the same or different Intune tenant. 
Most of Intune configuration information is exported in a form of JSON files. A small part of configuration data is saved in CSV files. 
The scripts have modular architecture where functions are combined into a single PowerShell module to facilitate installation and operations.

#Module name
**SRIntuneConfigManagement**

#Current version
**1.0**

#Supported functions

Invoke-SRIntuneBackupTenantInfo
Invoke-SRIntuneBackupAndroidDeviceEnrollmentProfile
Invoke-SRIntuneBackupAppProtectionPolicy
Invoke-SRIntuneBackupAppProtectionPolicyAssignment
Invoke-SRIntuneBackupAssignmentFilter
Invoke-SRIntuneBackupAutopilotDeploymentProfile
Invoke-SRIntuneBackupAutopilotDeploymentProfileAssignments
Invoke-SRIntuneBackupBrandingProfiles
Invoke-SRIntuneBackupBrandingProfilesAssignments
Invoke-SRIntuneBackupClientApp
Invoke-SRIntuneBackupClientAppAssignment
Invoke-SRIntuneBackupNotificationTemplates
Invoke-SRIntuneBackupConditionalAccessPolicy
Invoke-SRIntuneBackupConfigurationPolicy
Invoke-SRIntuneBackupConfigurationPolicyAssignment
Invoke-SRIntuneBackupDeviceCompliancePolicy
Invoke-SRIntuneBackupDeviceCompliancePolicyAssignment
Invoke-SRIntuneBackupDeviceConfiguration
Invoke-SRIntuneBackupDeviceConfigurationAssignment
Invoke-SRIntuneBackupDeviceEnrollmentConfig
Invoke-SRIntuneBackupDeviceEnrollmentConfigAssignments
Invoke-SRIntuneBackupDeviceHealthScript
Invoke-SRIntuneBackupDeviceHealthScriptAssignment
Invoke-SRIntuneBackupDeviceManagementIntent
Invoke-SRIntuneBackupDeviceManagementIntentAssignments
Invoke-SRIntuneBackupDeviceManagementScript
Invoke-SRIntuneBackupDeviceManagementScriptAssignment
Invoke-SRIntuneBackupGroupPolicyConfiguration
Invoke-SRIntuneBackupGroupPolicyConfigurationAssignment
Invoke-SRIntuneBackupGroups
Invoke-SRIntuneBackupScopeTag
Invoke-SRIntuneBackupWindowsDriverUpdateProfile
Invoke-SRIntuneBackupWindowsDriverUpdateProfileAssignments
Invoke-SRIntuneBackupWindowsFeatureUpdateProfile
Invoke-SRIntuneBackupWindowsFeatureUpdateProfileAssignments
Invoke-SRIntuneBackupWindowsQualityUpdateProfile
Invoke-SRIntuneBackupWindowsQualityUpdateProfileAssignments
Invoke-SRIntuneRestoreScopeTags
Invoke-SRIntuneRestoreGroups
Invoke-SRIntuneRestoreAssignmentFilter
Invoke-SRIntuneRestoreNotificationTemplates
Invoke-SRIntuneRestoreAndroidDeviceEnrollmentProfile
Invoke-SRIntuneRestoreAppProtectionPolicy
Invoke-SRIntuneRestoreAutopilotDeploymentProfile
Invoke-SRIntuneRestoreBrandingProfiles
Invoke-SRIntuneRestoreClientApps
Invoke-SRIntuneRestoreConditionalAccessPolicy
Invoke-SRIntuneRestoreDeviceCompliancePolicy
Invoke-SRIntuneRestoreDeviceConfiguration
Invoke-SRIntuneRestoreDeviceEnrollmentConfig
Invoke-SRIntuneRestoreDeviceHealthScript
Invoke-SRIntuneRestoreDeviceManagementIntent
Invoke-SRIntuneRestoreDeviceManagementScript
Invoke-SRIntuneRestoreGroupPolicyConfiguration
Invoke-SRIntuneRestoreWindowsDriverUpdateProfile
Invoke-SRIntuneRestoreWindowsFeatureUpdateProfile
Invoke-SRIntuneRestoreWindowsQualityUpdateProfile
Invoke-SRIntuneRestoreAppProtectionPolicyAssignment
Invoke-SRIntuneRestoreAutopilotDeploymentProfileAssignment
Invoke-SRIntuneRestoreBrandingProfilesAssignments
Invoke-SRIntuneRestoreClientAppAssignment
Invoke-SRIntuneRestoreDeviceCompliancePolicyAssignment
Invoke-SRIntuneRestoreDeviceConfigurationAssignment
Invoke-SRIntuneRestoreDeviceEnrollmentConfigAssignment
Invoke-SRIntuneRestoreDeviceHealthScriptAssignment
Invoke-SRIntuneRestoreDeviceManagementIntentAssignments
Invoke-SRIntuneRestoreDeviceManagementScriptAssignment
Invoke-SRIntuneRestoreGroupPolicyConfigurationAssignment
Invoke-SRIntuneRestoreWindowsDriverUpdateProfileAssignments
Invoke-SRIntuneRestoreWindowsFeatureUpdateProfileAssignments
Invoke-SRIntuneRestoreWindowsQualityUpdateProfileAssignments

#Open issues
NotificationMessageTemplates - restore is not working
Device compliance policies, scheduledActionsForRule - backup / restore not working
Restore of win32 apps is not working. Issues with intunewin file commit after uploading
windowsAutopilotDeploymentProfiles - restore of assignments is not working. It looks like a bug in MSGraph
Default enrollment configuration objects are not working

#Notes
The module uses MSGraph calls diretly without reliance on other PowerShell modules. Mainly Invoke-MgGraphRequest is used to make Graph calls.
Currently only delegated permissions are supported. Application permissions will need to be added at a later stage.

#Installation
The module can be downloaded and manually installed to a local folder. Import the module using the following command

`Import-Module .\SRIntuneConfigManagement.psd1`

#Creating Intune configuration backup
Use the following command to create a full backup of Intune configuration

`Start-SRIntuneBackup -Path C:\Temp\IntuneBackup`

Data is saved in a subfolder of the specified folder that points to the backed up Intune tenant and backup date and time
Example:
`C:\temp\IntuneBackup\Sunlab_0b57e92f-4bfc-4513-81af-dff5bed4c391_202405081504`

##Dependent object information
When backup is created DisplayName and id pairs are preserved in addition to json files in form of CSV files. This facilitates restore of object references when restoring in another tenant where reference objects have different ids. DisplayNames are used as keys. This concerns the following object types:
Azure AD groups
Assignment filters
Role Scope tags
Notification templates
Tenant

#Restoring Intune data from backup
DisplayName property is always used as the identificator of any object being restored. Objects in Intune always have IDs used a preimary identifyers. Restore actions always creates a new object with the same name if restore in the same tenant. DisplayName can be changed in json files to restore the object with another name.
Restore of assignments uses DisplayNames of the objects extracted from file names. Make sure that assignment json file names contain correct DisplayNames of restored objects.

To restore Intune configuration use the following command
`Start-SRIntuneRestoreConfig -Path C:\Temp\IntuneRestore -Assigments`

To perform partial restore simply remove files for objects that you don't want to restore from the restore folder.
When restoring into a different tenant always make sure that all CSV files are prsent in the restore folder in their corresponding subfolders. This is required to correctly restore references. Referenced objects must have already been restored in the target tenant. 
