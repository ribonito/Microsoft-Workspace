function Invoke-SRIntuneBackupDeviceManagementIntent {
    <#
    .SYNOPSIS
    Backup Intune Device Management Intents
    
    .DESCRIPTION
    Backup Intune Device Management Intents as JSON files per Device Management Intent to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupDeviceManagementIntent -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Management Intents")) {
        $null = New-Item -Path "$Path\Device Management Intents" -ItemType Directory
    }

    Write-Verbose "Requesting Intents"
    $Uri = "$ApiVersion/deviceManagement/intents"
    $intents = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($intent in $intents) {
        # Get the corresponding Device Management Template
        Write-Verbose "Requesting Template"
        $Uri = "$ApiVersion/deviceManagement/templates/$($intent.templateId)"
        $template = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        $templateDisplayName = ($template.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'

        # Get all setting categories in the Device Management Template
        Write-Verbose "Requesting Template Categories"
        $Uri = "$ApiVersion/deviceManagement/templates/$($intent.templateId)/categories"
        $templateCategories = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

        $intentSettingsDelta = @()
        foreach ($templateCategory in $templateCategories) {
            # Get all configured values for the template categories
            Write-Verbose "Requesting Intent Setting Values"
            $Uri = "$ApiVersion/deviceManagement/intents/$($intent.id)/categories/$($templateCategory.id)/settings"
            $intentSettingsDelta += Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        }

        $intentBackupValue = @{
            "displayName" = $intent.displayName
            "description" = $intent.description
            "settingsDelta" = $intentSettingsDelta
            "roleScopeTagIds" = $intent.roleScopeTagIds
        }

        $fileName = ("$($template.id)__$($intent.displayName)").Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $intentBackupValue | ConvertTo-Json | Out-File -LiteralPath "$path\Device Management Intents\$($templateDisplayName)__$($fileName).json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Device Management Intent"
            "Name"   = $intent.displayName
            "Path"   = "Device Management Intents\$($templateDisplayName)__$($fileName).json"
        }
    }
}

#Invoke-SRIntuneBackupDeviceManagementIntent -Path "C:\temp\IntuneBackup\FunctionTest"