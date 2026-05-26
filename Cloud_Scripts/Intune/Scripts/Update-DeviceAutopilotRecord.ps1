<#
.SYNOPSIS
Update autopilot record of a device or a list of devices

.DESCRIPTION
Update autopilot record of a device or a list of devices

.PARAMETER SerialNumber
Serial number of the device to be configured. Required for a single device.

.PARAMETER GroupTag
Group tag to be set for the device. Optional for a single device.

.PARAMETER UserUPN
UPN of the user to be assigned to the device. Optional for a single device.

.PARAMETER DeviceName
The name of the device. Optional for a single device.

.PARAMETER CSVFile
Full path to the CSV file containing a list of devices to be configured. Required for a single device.

.PARAMETER ApiVersion
Optional parameter to the version of MS graph API.

.EXAMPLE
Update-DeviceAutopilotRecord -CSVFile C:\temp\devices.csv -ApiVersion "v1.0"

.EXAMPLE
Update-DeviceAutopilotRecord -SerialNumber SJ48FJNW8 -GroupTag SRMW-AADJ-FR -UserUPN harry.potter@sunlab.ch -DeviceName PC0001

.NOTES
Requires Microsoft.Graph.Intune PowerShell Module

Connect to MSGraph first, using the 'Connect-Graph' cmdlet.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ParameterSetName="single")]
    [string]$SerialNumber,
    [Parameter(Mandatory = $false, ParameterSetName="single")]
    [string]$DeviceName,
    [Parameter(Mandatory = $false, ParameterSetName="single")]
    [string]$UserUPN,
    [Parameter(Mandatory = $false, ParameterSetName="single")]
    [string]$GroupTag,
    [Parameter(Mandatory = $true, ParameterSetName="bulk")]
    [string]$CSVFile,
    [Parameter(Mandatory = $false)]
    [ValidateSet("v1.0", "Beta")]
    [string]$ApiVersion = "Beta"
)

function Update-APRecord {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$sn,
        [Parameter(Mandatory = $false)]
        [string]$dname,
        [Parameter(Mandatory = $false)]
        [string]$upn,
        [Parameter(Mandatory = $false)]
        [string]$tag
    )

    #Set filter
    $QueryFilter = "?`$filter=contains(serialNumber,'$sn')"
    
    #Get the Autopilot record with spoecified serial number to find its ID
    $Uri = "$ApiVersion/deviceManagement/windowsAutopilotDeviceIdentities$QueryFilter"
    $DeviceApId = $(Invoke-MgGraphRequest -Uri $Uri | Get-MSGraphAllPages).Value.id

    # If device is found
    if ($DeviceApId) {
        $Params = @{}
        # add parameters specified in the command to be updated
        if($tag){ $Params.Add("groupTag","$tag") }
        if($upn){ 
            $Params.Add("userPrincipalName","$upn")
            # query Graph for the display name of the user to be added to the autopilot record
            $QueryFilter = "?`$filter=userPrincipalName eq '$upn'&`$select=displayName"
            $Uri = "$ApiVersion/users$QueryFilter"
            $UserDisplayName = $(Invoke-MgGraphRequest -Uri $Uri).Value.displayName
            If ($UserDisplayName) {
                $Params.Add("addressableUserName","$UserDisplayName")
            } else {
                Write-Error "User with UPN $upn wasn't find in the directory. we can't update the device record"
                Return
            }
        }
        if($dname){ $Params.Add("displayName","$dname") }

        If ($Params){
            #Convert array to json
            $Body = $Params | ConvertTo-Json
            #Update the autopilot record
            $Uri = "$ApiVersion/deviceManagement/windowsAutopilotDeviceIdentities/$DeviceApId/UpdateDeviceProperties"
            $Result = Invoke-MgGraphRequest -Uri $Uri -Method POST -Body $Body -ContentType 'application/json' -StatusCodeVariable httpStatus
            write-Output "Updating record for device: $serialnumber. Properties: $devicename | $userupn | $grouptag. Return status: $httpStatus"
        }
    } else {
        # If the device was not found display a message
        Write-Error "Device with serial number $SerialNumber was not found"
    }
}

#Validate parameters and setup variables
if ($PSBoundParameters.ContainsKey('CSVFile')) {
    if (-not (Test-Path "$CSVFile")) {
        Write-Output "File $CSVFile wasn't found. We cannot continue."
        Return 3
    }
    $CsvContent = Import-Csv -Path $CSVFile

} else {
    If (-not $SerialNumber){
        Write-Output "Serial number must be provided. We cannot continue."
        Return 3
    }
}

Import-Module Microsoft.Graph.Intune
#Connect-MSGraph | Out-Null
#Sing-in to MS Graph interactively with required scope
Connect-MgGraph -Scopes "Device.ReadWrite.All","User.Read.All","DeviceManagementManagedDevices.ReadWrite.All","DeviceManagementConfiguration.ReadWrite.All","DeviceManagementServiceConfig.ReadWrite.All" -NoWelcome

if ($CsvContent) {
    Foreach($row in $CsvContent) { 
        $Params = @{}
        foreach ($property in $row.PSObject.Properties)
        {
            switch ($($property.Name))
            {
                "SerialNumber" {$SerialNumber = $($property.Value)}
                "DeviceName" {$DeviceName = $($property.Value)}
                "AssignedUserUPN" {$UserUPN = $($property.Value)}
                "groupTag" {$groupTag = $($property.Value)}
            }
        } 
        Update-APRecord -sn $serialnumber -dname $devicename -upn $userupn -tag $grouptag

    }
} else {
    Update-APRecord -sn $serialnumber -dname $devicename -upn $userupn -tag $grouptag
}

# initiate a sync
$Uri = "$ApiVersion/deviceManagement/windowsAutopilotSettings/sync"
$Result = Invoke-MgGraphRequest -Uri $Uri -Method POST -StatusCodeVariable httpStatus
Write-Output "Requested record syncronisation. Return status: $httpStatus"
