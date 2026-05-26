function Invoke-SRIntuneBackupDeviceCompliancePolicyAssignment {
    <#
    .SYNOPSIS
    Backup Intune Device Complaince Policy Assignments
    
    .DESCRIPTION
    Backup Intune Device Complaince Policy Assignments as JSON files per Device Compliance Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupDeviceCompliancePolicyAssignment -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Create folder if not exists
    if (-not (Test-Path "$Path\Device Compliance Policies\Assignments")) {
        $null = New-Item -Path "$Path\Device Compliance Policies\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $Uri = "$ApiVersion/deviceManagement/deviceCompliancePolicies"
    $deviceCompliancePolicies = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($deviceCompliancePolicy in $deviceCompliancePolicies) {
        $Uri = "$ApiVersion/deviceManagement/deviceCompliancePolicies/$($deviceCompliancePolicy.id )/assignments"
        $assignments = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        if ($assignments) {
            $fileName = ($deviceCompliancePolicy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\Device Compliance Policies\Assignments\$fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Device Compliance Policy Assignments"
                "Name"   = $deviceCompliancePolicy.displayName
                "Path"   = "Device Compliance Policies\Assignments\$fileName.json"
            }
        }
    }
}

#Invoke-SRIntuneBackupDeviceCompliancePolicyAssignment -Path "C:\temp\IntuneBackup\FunctionTest"