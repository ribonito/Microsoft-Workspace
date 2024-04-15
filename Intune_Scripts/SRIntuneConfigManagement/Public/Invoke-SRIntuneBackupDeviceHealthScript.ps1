function Invoke-SRIntuneBackupDeviceHealthScript {
    <#
    .SYNOPSIS
    Backup Intune Health Scripts (Remediation scripts)

    .DESCRIPTION
    Backup Intune Health Scripts (Remediation scripts) as JSON files per Health Script to the specified Path.

    .PARAMETER Path
    Path to store backup files

    .EXAMPLE
    Invoke-SRIntuneBackupDeviceHealthScript -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Device Health Scripts")) {
        $null = New-Item -Path "$Path\Device Health Scripts" -ItemType Directory
    }

    $Uri = "$ApiVersion/deviceManagement/deviceHealthScripts"
    $healthScripts = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($healthScript in $healthScripts) {
        $fileName = ($healthScript.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'

        # Export the Health script profile
        $healthScript | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Device Health Scripts\$fileName.json"

        # Create folder if not exists
        if (-not (Test-Path "$Path\Device Health Scripts\Script Content")) {
            $null = New-Item -Path "$Path\Device Health Scripts\Script Content" -ItemType Directory
        }

        $Uri = "https://graph.microsoft.com/$ApiVersion/deviceManagement/deviceHealthScripts/$($healthScript.id)"
        $healthScriptObject = Invoke-MgGraphRequest -Uri $Uri
        $healthScriptDetectionContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($healthScriptObject.detectionScriptContent))
        $healthScriptDetectionContent | Out-File -LiteralPath "$path\Device Health Scripts\Script Content\$fileName`_detection.ps1"
        $healthScriptRemediationContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($healthScriptObject.remediationScriptContent))
        $healthScriptRemediationContent | Out-File -LiteralPath "$path\Device Health Scripts\Script Content\$fileName`_remediation.ps1"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Device Health Scripts"
            "Name"   = $healthScript.displayName
            "Path"   = "Device Health Scripts\$fileName.json"
        }
    }
}

#Invoke-SRIntuneBackupDeviceHealthScript -Path "C:\temp\IntuneBackup\FunctionTest"