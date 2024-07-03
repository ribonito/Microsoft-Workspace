#Overview

Intune configuration automation is a toolset built using PowerShell scripts with the purpose to allow saving of various configuration objects in an Intune tenant as well as additional information required for restoring the configuration in the same or different Intune tenant. 
Most of Intune configuration information is exported in a form of JSON files. A small part of configuration data is saved in CSV files. 
The scripts has modular architecture where functions are combined into a single PowerShell module to facilitate installation and operations.

#Module name
**SRIntuneConfigManagement**

#Current version
**1.1**

#Supported functions

- Invoke-SRIntuneBackupAdminRole
- Invoke-SRIntuneBackupAdminRoleAssignment
- Invoke-SRIntuneBackupAndroidDeviceEnrollmentProfile
- Invoke-SRIntuneBackupAppConfigurationPolicy
- Invoke-SRIntuneBackupAppConfigurationPolicyAssignment
- Invoke-SRIntuneBackupAppProtectionPolicy
- Invoke-SRIntuneBackupAppProtectionPolicyAssignment
- Invoke-SRIntuneBackupAssignmentFilter
- Invoke-SRIntuneBackupAutopilotDeploymentProfile
- Invoke-SRIntuneBackupAutopilotDeploymentProfileAssignments
- Invoke-SRIntuneBackupBrandingProfiles
- Invoke-SRIntuneBackupBrandingProfilesAssignments
- Invoke-SRIntuneBackupClientApp
- Invoke-SRIntuneBackupClientAppAssignment
- Invoke-SRIntuneBackupConditionalAccessPolicy
- Invoke-SRIntuneBackupConfigurationPolicy
- Invoke-SRIntuneBackupConfigurationPolicyAssignment
- Invoke-SRIntuneBackupDeviceCompliancePolicy
- Invoke-SRIntuneBackupDeviceCompliancePolicyAssignment
- Invoke-SRIntuneBackupDeviceConfiguration
- Invoke-SRIntuneBackupDeviceConfigurationAssignment
- Invoke-SRIntuneBackupDeviceEnrollmentConfig
- Invoke-SRIntuneBackupDeviceEnrollmentConfigAssignments
- Invoke-SRIntuneBackupDeviceHealthScript
- Invoke-SRIntuneBackupDeviceHealthScriptAssignment
- Invoke-SRIntuneBackupDeviceManagementIntent
- Invoke-SRIntuneBackupDeviceManagementIntentAssignments
- Invoke-SRIntuneBackupDeviceManagementScript
- Invoke-SRIntuneBackupDeviceManagementScriptAssignment
- Invoke-SRIntuneBackupGroupPolicyConfiguration
- Invoke-SRIntuneBackupGroupPolicyConfigurationAssignment
- Invoke-SRIntuneBackupGroups
- Invoke-SRIntuneBackupNotificationTemplates
- Invoke-SRIntuneBackupScopeTag
- Invoke-SRIntuneBackupTenantInfo
- Invoke-SRIntuneBackupWindowsDriverUpdateProfile
- Invoke-SRIntuneBackupWindowsDriverUpdateProfileAssignments
- Invoke-SRIntuneBackupWindowsFeatureUpdateProfile
- Invoke-SRIntuneBackupWindowsFeatureUpdateProfileAssignments
- Invoke-SRIntuneBackupWindowsQualityUpdateProfile
- Invoke-SRIntuneBackupWindowsQualityUpdateProfileAssignments
- Invoke-SRIntuneRestoreAdminRole
- Invoke-SRIntuneRestoreAdminRoleAssignment
- Invoke-SRIntuneRestoreAndroidDeviceEnrollmentProfile
- Invoke-SRIntuneRestoreAppConfigurationPolicy
- Invoke-SRIntuneRestoreAppConfigurationPolicyAssignment
- Invoke-SRIntuneRestoreAppProtectionPolicy
- Invoke-SRIntuneRestoreAppProtectionPolicyAssignment
- Invoke-SRIntuneRestoreAssignmentFilter
- Invoke-SRIntuneRestoreAutopilotDeploymentProfile
- Invoke-SRIntuneRestoreAutopilotDeploymentProfileAssignment
- Invoke-SRIntuneRestoreBrandingProfiles
- Invoke-SRIntuneRestoreBrandingProfilesAssignments
- Invoke-SRIntuneRestoreClientAppAssignment
- Invoke-SRIntuneRestoreClientApps
- Invoke-SRIntuneRestoreConditionalAccessPolicy
- Invoke-SRIntuneRestoreConfigurationPolicy
- Invoke-SRIntuneRestoreConfigurationPolicyAssignment
- Invoke-SRIntuneRestoreDeviceCompliancePolicy
- Invoke-SRIntuneRestoreDeviceCompliancePolicyAssignment
- Invoke-SRIntuneRestoreDeviceConfiguration
- Invoke-SRIntuneRestoreDeviceConfigurationAssignment
- Invoke-SRIntuneRestoreDeviceEnrollmentConfig
- Invoke-SRIntuneRestoreDeviceEnrollmentConfigAssignment
- Invoke-SRIntuneRestoreDeviceHealthScript
- Invoke-SRIntuneRestoreDeviceHealthScriptAssignment
- Invoke-SRIntuneRestoreDeviceManagementIntent
- Invoke-SRIntuneRestoreDeviceManagementIntentAssignments
- Invoke-SRIntuneRestoreDeviceManagementScript
- Invoke-SRIntuneRestoreDeviceManagementScriptAssignment
- Invoke-SRIntuneRestoreGroupPolicyConfiguration
- Invoke-SRIntuneRestoreGroupPolicyConfigurationAssignment
- Invoke-SRIntuneRestoreGroups
- Invoke-SRIntuneRestoreNotificationTemplates
- Invoke-SRIntuneRestoreScopeTags
- Invoke-SRIntuneRestoreWindowsDriverUpdateProfile
- Invoke-SRIntuneRestoreWindowsDriverUpdateProfileAssignments
- Invoke-SRIntuneRestoreWindowsFeatureUpdateProfile
- Invoke-SRIntuneRestoreWindowsFeatureUpdateProfileAssignments
- Invoke-SRIntuneRestoreWindowsQualityUpdateProfile
- Invoke-SRIntuneRestoreWindowsQualityUpdateProfileAssignments
- Start-SRIntuneBackup
- Start-SRIntuneRestoreConfig

##Authentication requirements
To obtain sufficient permissions for performing backup and restore operations in Intune using the PowerShell module, delagated permissions must be granted by a tenant administrator to Microsoft Graph Command Line Tools enterprise application. This can be done in advance or when prompted during authentication when the module is used in a tenant for the first time.    

For backup operations the following delegated permissions must be granted to Microsoft Graph Command Line Tools application:

- Policy.Read.All
- Policy.Read.ConditionalAccess
- Application.Read.All
- Group.Read.All
- DeviceManagementConfiguration.Read.All
- DeviceManagementApps.Read.All
- DeviceManagementRBAC.Read.All
- DeviceManagementServiceConfig.Read.All

For restore operations the following delegated permissions must be granted to Microsoft Graph Command Line Tools application:

- DeviceManagementManagedDevices.PrivilegedOperations.All
- DeviceManagementManagedDevices.ReadWrite.All
- DeviceManagementRBAC.ReadWrite.All
- DeviceManagementApps.ReadWrite.All
- DeviceManagementConfiguration.ReadWrite.All
- DeviceManagementServiceConfig.ReadWrite.All
- Group.ReadWrite.All
- GroupMember.ReadWrite.All
- Directory.ReadWrite.All
- RoleManagement.ReadWrite.Directory
- Policy.Read.All
- Policy.ReadWrite.ConditionalAccess
- Application.ReadWrite.All

#Open issues

- Device compliance policies, scheduledActionsForRule - backup / restore not working
- Restore of win32 apps is not working. Issues with intunewin file commit after uploading
- Default enrollment configuration objects are not working

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
- Azure AD groups
- Assignment filters
- Role Scope tags
- Notification templates
- Tenant
- Applications
- Administrative roles

#Restoring Intune data from backup
DisplayName property is always used as the identificator of any object being restored. Objects in Intune always have IDs used a preimary identifyers. Restore actions always creates a new object with the same name if restore in the same tenant. DisplayName can be changed in json files to restore the object with another name.
Restore of assignments uses DisplayNames of the objects extracted from file names. Make sure that assignment json file names contain correct DisplayNames of restored objects.

To restore Intune configuration use the following command
`Start-SRIntuneRestoreConfig -Path C:\Temp\IntuneRestore -Assigments`

To perform partial restore simply remove files for objects that you don't want to restore from the restore folder.
When restoring into a different tenant always make sure that all CSV files are prsent in the restore folder in their corresponding subfolders. This is required to correctly restore references. Referenced objects must have already been restored in the target tenant. 

#Release notes

v1.1
Added backup of administrative roles and role assignments. Only custom roles are backed up.

v1.2
Fixed restore of notification templates

v1.3
Fixed restore of Autopilot profile assignments
Added setting of mobiledevicemanagementauthority in the tenant

v1.4
added restore of custom Admin Roles
fixed missing delegated permissions when restoring groups

v1.5
bugfixes
Added restore of settings catalog policies and assignments
Added creation of missing service principles referenced in Conditinoal Access policies

v1.6
added iOS enrolment profiles
added restore of admin role assignments
bugfixes

v1.7
fixed issues with restore of Compliance Policy scheduled actions
minor bugfixes

v1.8
bugfixes
added support for administrative template policies based on custom ADMX files. ADMX files must still be uploaded manually before restoring the policies