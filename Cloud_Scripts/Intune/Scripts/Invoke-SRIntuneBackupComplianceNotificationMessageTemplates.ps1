function Invoke-SRIntuneBackupComplianceNotificationMessageTemplates {
    <#
    .SYNOPSIS
    Backup Intune compliance notification message templates
     
    .DESCRIPTION
    Backup Intune compliance notification message templates as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupComplianceNotificationMessageTemplates -Path "C:\temp"
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
    $Subfolder = "Device Compliance Policies\Notification Templates"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }
    if (-not (Test-Path "$Path\$Subfolder\LocalizedMessages")) {
        $null = New-Item -Path "$Path\$Subfolder\LocalizedMessages" -ItemType Directory
    }

    # Get all notification templates
    $Uri = "$ApiVersion/deviceManagement/notificationMessageTemplates"
    $Templates = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
    
    foreach ($Template in $Templates) {

        $fileName = ($Template.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $Template | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

        [PSCustomObject]@{
           "Action" = "Backup"
           "Type"   = "Compliance notification template"
           "Name"   = $Template.displayName
           "Path"   = "$Subfolder\$($fileName).json"
           }
        
        # Get localized messages for each template
        $Uri = "$ApiVersion/deviceManagement/notificationMessageTemplates/$($Template.id)/localizedNotificationMessages"
        $Messages = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

        if ($Messages) {
            foreach ($Message in $Messages) {
            $fileName = ($Message.id).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $Message | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\LocalizedMessages\$($fileName).json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Compliance notification message"
                "Name"   = $Message.id
                "Path"   = "$Subfolder\LocalizedMessages\$($fileName).json"
                }
            }
        }
    }
}

#Invoke-SRIntuneBackupComplianceNotificationMessageTemplates -Path "C:\temp\IntuneBackup\FunctionTest"