<#
.SYNOPSIS
    INT-017 | Intune / Autopilot - Reset Device and Update Autopilot Record for Re-Provisioning.

.DESCRIPTION
    Connects to Microsoft Graph, locates the Autopilot record by serial number,
    optionally triggers a Windows device reset (wipe), and then updates the
    Autopilot record with new Group Tag, Assigned User, and/or Device Name.

    Typical use case: Re-provisioning a device to a new user/group.

    Parameters:
        -SerialNumber → required: finds the device in Autopilot
        -GroupTag     → optional: assigns a new group tag
        -UserUPN      → optional: assigns a new user to the device
        -DeviceName   → optional: sets the device display name
        -InitiateReset → if true, sends a cleanWindowsDevice command (full wipe)
        -WaitForReset  → if true, waits 60 seconds then syncs the device

.PRODUCT
    Microsoft Intune / Windows Autopilot / Microsoft Graph

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.PARAMETER SerialNumber
    Serial number of the target device. Required.

.PARAMETER GroupTag
    Group tag to assign to the device in Autopilot.

.PARAMETER UserUPN
    UPN of the user to assign to the device.

.PARAMETER DeviceName
    Display name to set in the Autopilot record.

.PARAMETER ApiVersion
    Graph API version. Default: "Beta".

.PARAMETER InitiateReset
    If $true, sends a device wipe (cleanWindowsDevice) command.

.PARAMETER WaitForReset
    If $true, waits 60 seconds after reset and triggers a device sync.

.EXAMPLE
    # Wipe and reassign device to new user
    .\INT-017_Reset-DeviceForAutopilot.ps1 -SerialNumber "ABC123" -UserUPN "newuser@contoso.com" -GroupTag "CORP" -InitiateReset $true

.NOTES
    - Module: Microsoft.Graph.Intune
    - Required scopes: Device.ReadWrite.All, User.Read.All, DeviceManagement*.ReadWrite.All
#>

#region ── Parameters ─────────────────────────────────────────────────────────
param(
    [Parameter(Mandatory = $true)]
    [string]$SerialNumber,
    [Parameter(Mandatory = $false)]
    [string]$GroupTag,
    [Parameter(Mandatory = $false)]
    [string]$UserUPN,
    [Parameter(Mandatory = $false)]
    [string]$DeviceName,
    [Parameter(Mandatory = $false)]
    [ValidateSet("v1.0", "Beta")]
    [string]$ApiVersion = "Beta",
    [Parameter(Mandatory = $false)]
    [boolean]$InitiateReset = $false,
    [Parameter(Mandatory = $false)]
    [boolean]$WaitForReset = $false
)
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
Import-Module Microsoft.Graph.Intune
# Sign-in to MS Graph interactively with required scope
Connect-MgGraph -Scopes "Device.ReadWrite.All","User.Read.All","DeviceManagementManagedDevices.ReadWrite.All","DeviceManagementConfiguration.ReadWrite.All","DeviceManagementServiceConfig.ReadWrite.All" -NoWelcome

#Set filter
$QueryFilter = "?`$filter=contains(serialNumber,'$SerialNumber')"

#Get the Autopilot record with specified serial number to find its ID
$Uri = "$ApiVersion/deviceManagement/windowsAutopilotDeviceIdentities$QueryFilter"
$DeviceAP = $(Invoke-MgGraphRequest -Uri $Uri | Get-MSGraphAllPages).Value

# If device is found
if ($DeviceAP) {
    If($InitiateReset){
        # set body parameter to clean user data
        $Params = @{}
        $Params.Add("keepUserData","false")
        #Convert array to json
        $Body = $Params | ConvertTo-Json
        #Kick off device reset
        $Uri = "$ApiVersion/deviceManagement/managedDevices/$($DeviceAP.managedDeviceId)/cleanWindowsDevice"
        $Result = Invoke-MgGraphRequest -Uri $Uri -Method POST -Body $Body -ContentType 'application/json'

        # Wait 3 minutes and sync the device to speed up the reset
        Start-Sleep -Seconds 60
        $Uri = "$ApiVersion/deviceManagement/managedDevices/$($DeviceAP.managedDeviceId)/syncDevice"
        $Result = Invoke-MgGraphRequest -Uri $Uri -Method POST
    }

    # Update autopilot record of the device and sync
    $Params = @{}
    # add parameters specified in the command to be updated
    if($GroupTag){ $Params.Add("groupTag","$groupTag") }
    if($UserUPN){ 
        $Params.Add("userPrincipalName","$UserUPN")
        # query Graph for the display name of the user to be added to the autopilot record
        $QueryFilter = "?`$filter=userPrincipalName eq '$UserUPN'&`$select=displayName"
        $Uri = "$ApiVersion/users$QueryFilter"
        $UserDisplayName = $(Invoke-MgGraphRequest -Uri $Uri).Value.displayName
        $Params.Add("addressableUserName","$UserDisplayName")
    }
    if($DeviceName){ $Params.Add("displayName","$DeviceName") }

    If ($Params){
        #Convert array to json
        $Body = $Params | ConvertTo-Json
        #Update the autopilot record
        $Uri = "$ApiVersion/deviceManagement/windowsAutopilotDeviceIdentities/$($DeviceAP.id)/UpdateDeviceProperties"
        $Result = Invoke-MgGraphRequest -Uri $Uri -Method POST -Body $Body -ContentType 'application/json'

        # initiate a sync
        $Uri = "$ApiVersion/deviceManagement/windowsAutopilotSettings/sync"
        $Result = Invoke-MgGraphRequest -Uri $Uri -Method POST
    }
} else {
    # If the device was not found display a message
    Write-Host "Device with serial number $SerialNumber was not found"
}
#endregion
