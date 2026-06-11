<#
.SYNOPSIS
    INT-014 | Intune Proactive Remediation - REMEDIATE: Rename Hybrid AD Joined Device per Autopilot Record.

.DESCRIPTION
    Remediation script for an Intune Proactive Remediation package.
    Renames the device to the name stored in its Windows Autopilot record (via Microsoft Graph).

    Flow:
        1. Connects to Microsoft Graph using Client Credentials (app-only)
        2. Retrieves the device serial number from WMI
        3. Queries the Autopilot record for the expected device name
        4. If device name matches → marks completion in registry and exits 0
        5. If device is AD domain-joined and DC reachable → renames and schedules restart
        6. Writes completion tag: HKLM\Software\Sunrise\Manage\HAADJComputerRename = 1

    Exit codes:
        0   = Rename not needed OR completed successfully
        1   = Cannot rename (no connectivity, AP record empty, domain issue)
        1641 = Hard reboot required (during OOBE/ESP)
        3010 = Soft reboot scheduled (60 min)

    Deploy paired with INT-013 (HybridCompuerRename-detect.ps1).

.PRODUCT
    Microsoft Intune / Windows Autopilot / Hybrid AD Join / Proactive Remediation

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.NOTES
    - Module: Microsoft.Graph.Authentication, Microsoft.Graph.Intune (auto-installed)
    - Requires App Registration with DeviceManagementManagedDevices.Read.All
    - Logs to: %ProgramData%\Microsoft\IntuneManagementExtension\Logs\
    - Update $ClientId, $TenantId, and $ClientSecret before deployment

.EXAMPLE
    Run automatically by Intune Proactive Remediation (not called manually)
#>

#region ── Configuration ──────────────────────────────────────────────────────
$ClientId = "05f7e286-a51f-4d4e-b820-da5d3167c3c7"
$TenantId = "0b57e92f-4bfc-4513-81af-dff5bed4c391"
$ClientSecret = "WUo8Q~2wxmApVln5ULJ8H6Y1qd2Dp4Hkn6nIzcdE"

# Start logging
$DateTime = Get-Date -Format "MM-dd-yyyy-HH-mm"
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\SetHHADJComputerName-remediate.log"
Start-Transcript $LogPath -Append
Write-Host "----------------------------------------------------"
Write-Host "$(Get-Date):  Script started"
#endregion

#region ── Authentication ─────────────────────────────────────────────────────
#Install required modules if not present
Install-PackageProvider -Name NuGet -Confirm:$false -Force:$true
Install-Module -Name Microsoft.Graph.Authentication -Confirm:$false -Force:$true
Install-Module -Name Microsoft.Graph.Intune -Confirm:$false -Force:$true

# Convert the client secret to a secure string
$ClientSecretPass = ConvertTo-SecureString -String $ClientSecret -AsPlainText -Force

# Create a credential object using the client ID and secure string
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $ClientSecretPass

# Connect to Microsoft Graph with Client Secret
Connect-MgGraph -TenantId $tenantId -ClientSecretCredential $ClientSecretCredential
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
#Get the serial number of the device
$SerialNumber = (Get-WmiObject -Class Win32_SystemEnclosure).SerialNumber
Write-Host "Device serial number from WMI: $SerialNumber"

#Get the name of the device
$details = Get-ComputerInfo
$ActualName = $details.CsName
Write-Host "Device actual name from WMI: $ActualName"

#Set graph query filter
$QueryFilter = "?`$filter=contains(serialNumber,'$SerialNumber')"
$ApiVersion = "beta"

#Get the Autopilot record with specified serial number to get the name set in the AP record
$Uri = "$ApiVersion/deviceManagement/windowsAutopilotDeviceIdentities$QueryFilter"
$DeviceNameAP = $(Invoke-MgGraphRequest -Uri $Uri | Get-MSGraphAllPages).Value.displayName

if($DeviceNameAP -eq "" -or $DeviceNameAP -eq $null) {
    Write-Host "Device name in Autopilot record is empty or cannot get it from MSGraph. Rename cannot happen at this time."
    Stop-Transcript
    Exit 1
} else {
    Write-Host "Device name specified in the Autopilot record: $DeviceNameAP"
    if ($DeviceNameAP -eq $ActualName){
        Write-Host "Device name corresponds to Autopilot record. Rename has been completed or not required. Setting a tag in the registry: HKLM\Software\Sunrise\Manage\HAADJComputerRename=1"
        #Set a tag in the registry to avoid further name checks in future
        REG add "HKLM\Software\Sunrise\Manage" /v "HAADJComputerRename" /t REG_DWORD /d 1 /f
        Stop-Transcript
        Exit 0
    } else {
        # PC name is different from the AP record. Proceed with rename of the computer
        # See if we are AD joined
        if ($details.CsPartOfDomain) {
            Write-Host "Device is joined to AD domain: $($details.CsDomain)"

            # Make sure we have connectivity
            $dcInfo = [ADSI]"LDAP://RootDSE"
            if ($null -eq $dcInfo.dnsHostName) {
                Write-Host "No connectivity to the domain, unable to rename at this point."
                Stop-Transcript
                Exit 1
            } else {
                # Set the computer name
                Write-Host "Renaming computer to $DeviceNameAP"
                $Result = Rename-Computer -NewName $DeviceNameAP -Force -Passthru
                If($($Result.HasSucceeded)) {
                    # Make sure we reboot if still in ESP/OOBE by reporting a 1641 return code (hard reboot)
                    if ($details.CsUserName -match "defaultUser"){
                        Write-Host "Exiting during ESP/OOBE. Restart will not be initiated."
                        Write-Host "Device name corresponds to Autopilot record. Rename has been completed or not required. Setting a tag in the registry: HKLM\Software\Sunrise\Manage\HAADJComputerRename=1"
                        #Set a tag in the registry to avoid further name checks in future
                        REG add "HKLM\Software\Sunrise\Manage" /v "HAADJComputerRename" /t REG_DWORD /d 1 /f
                        Stop-Transcript
                        Exit 1641
                    } else {
                        Write-Host "Initiating a restart in 60 minutes"
                        & shutdown.exe /g /t 3600 /f /c "Restarting the computer in 60 minutes due to a computer name change. Save your work! You can restart computer yourself at any time."
                        Stop-Transcript
                        Exit 0
                    }
                } else {
                    Write-Host "Renaming of the computer failed."
                    Stop-Transcript
                    Exit 1
                }
            }        
        } else {
            Write-Host "Not part of a AD domain. Rename cannot be done at this time."
            Stop-Transcript
            Exit 1
        }
    }
}
#endregion
