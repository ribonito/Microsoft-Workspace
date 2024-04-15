    [CmdletBinding()]
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

Import-Module Microsoft.Graph.Intune
#Connect-MSGraph | Out-Null
#Sing-in to MS Graph interactively with required scope
Connect-MgGraph -Scopes "Device.ReadWrite.All","User.Read.All","DeviceManagementManagedDevices.ReadWrite.All","DeviceManagementConfiguration.ReadWrite.All","DeviceManagementServiceConfig.ReadWrite.All" -NoWelcome

#Set filter
$QueryFilter = "?`$filter=contains(serialNumber,'$SerialNumber')"

#Get the Autopilot record with spoecified serial number to find its ID
$Uri = "$ApiVersion/deviceManagement/windowsAutopilotDeviceIdentities$QueryFilter"
$DeviceAP = $(Invoke-MgGraphRequest -Uri $Uri | Get-MSGraphAllPages).Value
#$DeviceApId = $(Invoke-MgGraphRequest -Uri $Uri | Get-MSGraphAllPages).Value.id
#$DeviceManId = $(Invoke-MgGraphRequest -Uri $Uri | Get-MSGraphAllPages).Value.managedDeviceId

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
