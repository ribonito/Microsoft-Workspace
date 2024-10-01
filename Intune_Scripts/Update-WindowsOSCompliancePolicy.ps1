<#
.SYNOPSIS
Updates Sunrise standard Windows OS version device compliance policy
 
.DESCRIPTION
Updates Sunrise standard Windows OS version device compliance policy
   
.PARAMETER tenantId
ID of the Intune tenant.
    
.EXAMPLE
Update-SRWindowsOSCOmpliancePolicy -tenantId 0b57e92f-4bfc-4513-81af-dff5bed4c398f6a1
    
.NOTES
Requires the Microsoft.Graph.Intune PowerShell Module
#>
    
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$tenantId
)


$ApiVersion = "Beta"
$PolicyName = "SRMW-Win-Compliance-OS"

#Connect to Graph
Import-Module Microsoft.Graph.Intune
Connect-MgGraph -TenantID $tenantID -Scopes DeviceManagementManagedDevices.PrivilegedOperations.All,DeviceManagementManagedDevices.ReadWrite.All,DeviceManagementConfiguration.ReadWrite.All,WindowsUpdates.Read.All

# Get the Device configuration we are restoring the assignments for
$Uri = "$ApiVersion/deviceManagement/deviceCompliancePolicies?`$filter=displayName eq '$PolicyName'"
$deviceComplianceObject = Invoke-MgGraphRequest -Uri $Uri
if (-not ($deviceComplianceObject.Value)) {
    Write-Error "Error retrieving Device compliance policy: $PolicyName."
    Exit 3
} else {
    Write-Output "Updating device compliance policy: $PolicyName."
}

# Create a list of Patch Tuesdays
$PatchTuesdays = foreach ($y in $(((get-date).adddays(-365)).year)..$(((get-date).adddays(365)).year)){
    foreach($m in 1..12){
        $f=[datetime]([string]$m + "/1/$y");(0..30|%{$f.adddays($_)}|?{$_.dayofweek -like "Tue*"})[1]
    }
}

# Get OS revisions from MSGrpah from each OS build configured in the policy
foreach($osVersion in $deviceComplianceObject.value.validOperatingSystemBuildRanges){
    $WinBuild = $($osVersion.lowestVersion).Split(".")[2]
    $Uri = "$ApiVersion/admin/windows/updates/products`?expand=revisions&filter=revisions/any(p:p/osBuild/buildNumber eq $WinBuild)"
    $Revisions = Invoke-MgGraphRequest -Uri $Uri
    if (-not ($Revisions.Value)) {
        Write-Error "Error retrieving OS updates from Graph for build: $WinBuild."
        Exit 3
    }
    # filter out revisions released on a days other than a patch tuesday and set the N - 1 release version in the policy
    $filteredRevisions = $Revisions.value.revisions | Where-Object {$_.releaseDateTime -in $PatchTuesdays} | Select-Object -first 2
    $Nmin1Revision = $filteredRevisions | Sort-Object -Property releaseDateTime -Descending | Select-Object -Last 1
    Write-Output "Setting selected N-1 OS build: $($Nmin1Revision.id) in the policy."
    $osVersion.lowestVersion = $Nmin1Revision.id
}

# Create request body object
$requestBody = @{
    "id" = $deviceComplianceObject.value.id
    "@odata.type" = $deviceComplianceObject.value.'@odata.type'
    "validOperatingSystemBuildRanges" = $deviceComplianceObject.value.validOperatingSystemBuildRanges
}
# Convert the PowerShell object to JSON
$requestBody = $requestBody | ConvertTo-Json -Depth 10

# Update the policy
try {
    $Uri = "$ApiVersion/deviceManagement/deviceCompliancePolicies/$($deviceComplianceObject.Value.id)"
    $result = Invoke-MgGraphRequest -Method PATCH -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
} catch {
    Write-Error "$($deviceComplianceObject.Value.displayName) - Failed to update Device Compliance Policy" -Verbose
    Write-Error $_ -ErrorAction Continue
    Disconnect-MgGraph
    Exit 3
}

Write-Output "Successfully updated the policy."
Disconnect-MgGraph
Exit 0
