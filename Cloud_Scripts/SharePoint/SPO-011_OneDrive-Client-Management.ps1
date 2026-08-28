<#
.SYNOPSIS
    SPO-011 | OneDrive Client Management.

.DESCRIPTION
    Manage OneDrive sync client settings and policies.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (SPO-011 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/SharePoint%20Online/OneDrive%20Client%20Management.ps1

.NOTES
    Name: SPO-011_OneDrive-Client-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Common example registry paths. #>
$reg_path = "";
$reg_path = "HKCU:\";
$reg_path = "HKCU:\Software\Microsoft\Office\16.0"
$reg_path = "HKLM:\";
$reg_path = "HKLM:\Software\Microsoft\Windows\OneDrive";


<# Interactive: Registry type selection. #>
$list_regtypes = "REG_BINARY", "REG_DWORD", "REG_DWORD_LITTLE_ENDIAN", "REG_DWORD_BIG_ENDIAN", "REG_EXPAND_SZ", "REG_LINK", "REG_MULTI_SZ", "REG_NONE", "REG_QWORD", "REG_QWORD_LITTLE_ENDIAN", "REG_SZ";
$reg_type = $list_regtypes | Out-GridView -OutputMode Single;

<# Create or set registry key . #>
$reg_type = "";
$reg_path = "";
$reg_name = "";
$reg_value = "";
New-ItemProperty -PropertyType $reg_type -Path $reg_path -Name $reg_name -Value $reg_value -Force;

<# Remove a registry entry. #>
$reg_path = "";
$reg_name = "";
Remove-ItemProperty -Path $reg_path -Name $reg_name -Force;


<# Prevent the usage of OneDrive for file storage. #>
$reg_path = "HKLM:\Software\Microsoft\Windows\OneDrive";
$reg_name = "DisableFileSyncNGSC";

<# Prevent users from syncing personal OneDrive accounts. #>
$reg_path = "HKLM:\Software\Microsoft\Windows\OneDrive";
$reg_name = "DisablePersonalSync";

<# Disable the tutorial that appears at the end of OneDrive Setup. #>
$reg_path = "HKLM:\Software\Microsoft\Windows\OneDrive";
$reg_name = "DisableTutorial";

<# Use OneDrive Files On-Demand. #>
$reg_path = "HKLM:\Software\Microsoft\Windows\OneDrive";
$reg_name = "FilesOnDemandEnabled";
