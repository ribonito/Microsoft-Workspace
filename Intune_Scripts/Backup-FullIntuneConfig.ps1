#This script requires IntuneBackupAndRestore module
#Install-Module IntuneBackupAndRestore -Force

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RootPath = "C:\temp\IntuneBackup")

$TimeStamp = $ts = Get-Date -f "yyyyMMddHHmm"
$RootPath = "$RootPath\$TimeStamp"
$TenantID = "0b57e92f-4bfc-4513-81af-dff5bed4c391"
$GroupIDs = @{}

Import-Module Microsoft.Graph.Intune
Import-Module IntuneBackupAndRestore
Connect-MSGraph | Out-Null
Connect-MgGraph -Scopes "Policy.Read.All","Policy.ReadWrite.ConditionalAccess","Application.Read.All","Group.Read.All" -NoWelcome

Start-IntuneBackup -Path $RootPath


function Invoke-SRIntuneDeviceEnrollmentConfig {
    <#
    .SYNOPSIS
    Backup Intune Device Enrollment Configuration
     
    .DESCRIPTION
    Backup Intune Device Enrollment Configuration as JSON files per Device Enrollment configuration item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneDeviceEnrolmentConfig -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Create folder if not exists
    $Subfolder = "Device Enrollment"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Enrolment configurations
    $eConfigs = Invoke-MSGraphRequest -Url 'deviceManagement/deviceEnrollmentConfigurations' | Get-MSGraphAllPages

    foreach ($eConfig in $eConfigs) {
        $eConfigType = $($eConfig.deviceEnrollmentConfigurationType)

        $fileName = ($eConfig.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $eConfig | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($eConfigType)_$($fileName).json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Device Enrolment"
            "Name"   = $eConfig.displayName
            "Path"   = "$Subfolder\$($eConfigType)_$($fileName).json"
        }
    }
}

function Invoke-SRIntuneDeviceEnrollmentConfigAssignments {
    <#
    .SYNOPSIS
    Backup Intune Device Enrollment Configuration assignments
     
    .DESCRIPTION
    Backup Intune Device Enrollment Configuration assignments as JSON files per Device Enrollment configuration item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneDeviceEnrolmentConfig -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Create folder if not exists
    $Subfolder = "Device Enrollment\Assignments"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Enrollment configuration assigments
    $eConfigs = Invoke-MSGraphRequest -Url 'deviceManagement/deviceEnrollmentConfigurations' | Get-MSGraphAllPages #| Select-Object -ExpandProperty Value

    foreach ($eConfig in $eConfigs) {
        $eConfigType = $($eConfig.deviceEnrollmentConfigurationType)
        $assignments = Invoke-MSGraphRequest -Url "https://graph.microsoft.com/$ApiVersion/deviceManagement/deviceEnrollmentConfigurations/$($eConfig.id)/assignments"

        if ($assignments) {
            $fileName = ($eConfig.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($eConfigType)_$($fileName).json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Device Enrolment configuration assignment"
                "Name"   = $eConfig.displayName
                "Path"   = "$Subfolder\$($eConfigType)_$($fileName).json"
            }
        }
    }
}

function Invoke-SRIntuneAutopilotDeploymentProfile {
    <#
    .SYNOPSIS
    Backup Intune Autopilot Deployment Profiles
     
    .DESCRIPTION
    Backup Intune Autopilot Deployment Profiles as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneAutopilotDeploymentProfile -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Create folder if not exists
    $Subfolder = "Autopilot Deployment Profiles"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Autopilot profiles
    $Profiles = Invoke-MSGraphRequest -Url 'deviceManagement/windowsAutopilotDeploymentProfiles' | Get-MSGraphAllPages

    foreach ($Profile in $Profiles) {
        $ProfileType = $($Profile.deviceEnrollmentConfigurationType)

        $fileName = ($Profile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $Profile | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Autopilot Deployment Profile"
            "Name"   = $Profile.displayName
            "Path"   = "$Subfolder\$($fileName).json"
        }
    }
}

function Invoke-SRIntuneAutopilotDeploymentProfileAssignments {
    <#
    .SYNOPSIS
    Backup Intune Autopilot Deployment Profile assignments
     
    .DESCRIPTION
    Backup Intune Autopilot Deployment Profile assignments as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneAutopilotDeploymentProfileAssignments -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Create folder if not exists
    $Subfolder = "Autopilot Deployment Profiles\Assignments"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Autopilot profile assignments
    $Profiles = Invoke-MSGraphRequest -Url 'deviceManagement/windowsAutopilotDeploymentProfiles' | Get-MSGraphAllPages

    foreach ($Profile in $Profiles) {
        $assignments = Invoke-MSGraphRequest -Url "https://graph.microsoft.com/$ApiVersion/deviceManagement/windowsAutopilotDeploymentProfiles/$($Profile.id)/assignments"

        if ($assignments) {
            $fileName = ($Profile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Autopilot Deployment Profile assignment"
                "Name"   = $Profile.displayName
                "Path"   = "$Subfolder\$($fileName).json"
            }
        }
    }
}

function Invoke-SRIntuneConditionalAccessPolicy {
    <#
    .SYNOPSIS
    Backup Intune Conditional Access Policy
     
    .DESCRIPTION
    Backup Intune Conditional Access Policies as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneConditionalAccessPolicy -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Create folder if not exists
    $Subfolder = "Conditional Access Policies"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Conditional Access policies
    $Uri = "$ApiVersion/identity/conditionalAccess/policies"
    $Policies = $(Invoke-MgGraphRequest -Uri $Uri | Get-MSGraphAllPages).Value
    
    foreach ($Policy in $Policies) {
        $fileName = ($Policy.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $Policy | ConvertTo-Json -Depth 10 | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Conditional Access Policy"
            "Name"   = $Policy.displayName
            "Path"   = "$Subfolder\$($fileName).json"
        }
    }
}

function Invoke-SRIntuneGroups {
    <#
    .SYNOPSIS
    Backup Intune Gropups
     
    .DESCRIPTION
    Backup Intune related AAD groups (filtered) as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneGroups -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    #Set filter
    $QueryFilter = "?`$filter=startswith(displayName, 'SRMW_')"

    # Set the Microsoft Graph API endpoint
    if (-not ((Get-MSGraphEnvironment).SchemaVersion -eq $apiVersion)) {
        Update-MSGraphEnvironment -SchemaVersion $apiVersion -Quiet
        Connect-MSGraph -ForceNonInteractive -Quiet
    }

    # Create folder if not exists
    $Subfolder = "Groups"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all group with names starting with 'SRMW_'
    $Uri = "$ApiVersion/groups$QueryFilter"
    $Groups = $(Invoke-MgGraphRequest -Uri $Uri | Get-MSGraphAllPages).Value 
    
    foreach ($Group in $Groups) {
        $fileName = ($Group.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $Group | ConvertTo-Json -Depth 10 | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

        #Store group name and id in a hash table
        $GroupIDs.Add($Group.id, $Group.displayName)

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Group"
            "Name"   = $Group.displayName
            "Path"   = "$Subfolder\$($fileName).json"
        }
    }
    #Store group hash table in a CSV file
    $GroupIDs.GetEnumerator() | Select-Object Key, Value | Export-CSV -path "$Path\$Subfolder\GroupIDs.csv" -NoTypeInformation
}

Invoke-SRIntuneDeviceEnrollmentConfig -Path $RootPath
Invoke-SRIntuneDeviceEnrollmentConfigAssignments -Path $RootPath
Invoke-SRIntuneAutopilotDeploymentProfile -Path $RootPath
Invoke-SRIntuneAutopilotDeploymentProfileAssignments -Path $RootPath
Invoke-SRIntuneConditionalAccessPolicy -Path $RootPath
Invoke-SRIntuneGroups -Path $RootPath
