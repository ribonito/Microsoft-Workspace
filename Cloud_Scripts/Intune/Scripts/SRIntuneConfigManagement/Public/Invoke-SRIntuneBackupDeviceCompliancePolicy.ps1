function Invoke-SRIntuneBackupDeviceCompliancePolicy {
    <#
    .SYNOPSIS
    Backup Intune Device Compliance Policies
    
    .DESCRIPTION
    Backup Intune Device Compliance Policies as JSON files per Device Compliance Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupDeviceCompliancePolicy -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Compliance Policies")) {
        $null = New-Item -Path "$Path\Device Compliance Policies" -ItemType Directory
    }


    # Get all policies
    $Uri = "$ApiVersion/deviceManagement/deviceCompliancePolicies"
    $deviceCompliancePolicies = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    # Get details of each Device Compliance Policy
    foreach ($deviceCompliancePolicy in $deviceCompliancePolicies) {
        $Uri = "$ApiVersion/deviceManagement/deviceCompliancePolicies/$($deviceCompliancePolicy.id)?`$expand=scheduledActionsForRule(`$expand=scheduledActionConfigurations)"
        $deviceCompliancePolicyDetails = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        $fileName = ($deviceCompliancePolicyDetails.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $deviceCompliancePolicyDetails | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Device Compliance Policies\$fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Device Compliance Policy"
            "Name"   = $deviceCompliancePolicyDetails.displayName
            "Path"   = "Device Compliance Policies\$fileName.json"
        }
    }
}

#Invoke-SRIntuneBackupDeviceCompliancePolicy -Path "C:\temp\IntuneBackup\FunctionTest"