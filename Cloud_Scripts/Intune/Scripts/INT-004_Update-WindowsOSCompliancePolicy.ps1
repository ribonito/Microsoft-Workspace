<#
.SYNOPSIS
    INT-004 | Intune - Update Windows OS Compliance Policy to N-1 Patch Tuesday Build.

.DESCRIPTION
    Automatically updates the Windows OS version range in a specified Intune Device Compliance
    Policy to enforce the N-1 (previous) Patch Tuesday Windows build.

    How it works:
        1. Connects to Microsoft Graph with the required scopes
        2. Retrieves the target Device Compliance Policy by name
        3. Fetches the list of all Patch Tuesdays (±1 year)
        4. For each OS build defined in the policy, queries Graph for available revisions
        5. Filters revisions released on Patch Tuesdays and selects N-1 (one release back)
        6. Updates the policy's lowestVersion with the N-1 build ID

    This ensures devices are compliant with a "one version behind current" policy,
    giving time for the latest update to be validated before enforcement.

.PRODUCT
    Microsoft Intune / Windows Update for Business / Microsoft Graph

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.PARAMETER tenantId
    ID of the Intune tenant (GUID format).

.EXAMPLE
    .\INT-004_Update-WindowsOSCompliancePolicy.ps1 -tenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

.NOTES
    Requires the Microsoft.Graph.Intune PowerShell Module.
    Policy name is hardcoded as $PolicyName = "SRMW-Win-Compliance-OS" — update as needed.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$tenantId
)
#endregion

#region ── Connection & Setup ─────────────────────────────────────────────────
$ApiVersion = "Beta"
$PolicyName = "SRMW-Win-Compliance-OS"

#Connect to Graph
Import-Module Microsoft.Graph.Intune
Connect-MgGraph -TenantID $tenantID -Scopes DeviceManagementManagedDevices.PrivilegedOperations.All,DeviceManagementManagedDevices.ReadWrite.All,DeviceManagementConfiguration.ReadWrite.All,WindowsUpdates.Read.All -NoWelcome

# Get the Device configuration we are restoring the assignments for
$Uri = "$ApiVersion/deviceManagement/deviceCompliancePolicies?`$filter=displayName eq '$PolicyName'"
$deviceComplianceObject = Invoke-MgGraphRequest -Uri $Uri
if (-not ($deviceComplianceObject.Value)) {
    Write-Error "Error retrieving Device compliance policy: $PolicyName."
    Exit 3
} else {
    Write-Output "Updating device compliance policy: $PolicyName."
}
#endregion

#region ── Fetch Patch Tuesdays ───────────────────────────────────────────────
# Create a list of Patch Tuesdays
$PatchTuesdays = foreach ($y in $(((get-date).adddays(-365)).year)..$(((get-date).adddays(365)).year)){
    foreach($m in 1..12){
        $f=[datetime]([string]$m + "/1/$y");(0..30|%{$f.adddays($_)}|?{$_.dayofweek -like "Tue*"})[1]
    }
}
#endregion

#region ── Fetch and Update Policy ───────────────────────────────────────────
# Get OS revisions from MSGraph from each OS build configured in the policy
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
#endregion

#region ── Save and Enforce Policy ────────────────────────────────────────────
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
#endregion
