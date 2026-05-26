function Invoke-SRIntuneBackupNotificationTemplates {
    <#
    .SYNOPSIS
    Backup Intune Backup Notification message templates
     
    .DESCRIPTION
    Backup Intune Backup Notification message templates as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupNotificationTemplates -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $Nmts = @{}
    # Create folder if not exists
    $Subfolder = "Notification templates"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get Intune Assignment Filters
    $Uri = "$ApiVersion/deviceManagement/notificationMessageTemplates?`$expand=localizedNotificationMessages"
    $Profiles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($Profile in $Profiles) {
        $fileName = ($Profile.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $Profile | ConvertTo-Json | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"
        #Store group name and id in a hash table
        $Nmts.Add($Profile.id, $Profile.displayName)

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Backup Notification message templates"
            "Name"   = $Profile.displayName
            "Path"   = "$Subfolder\$($fileName).json"
        }
    }
    #Store group hash table in a CSV file
    $Nmts.GetEnumerator() | Select Key, Value | Export-CSV -path "$Path\$Subfolder\NotifMsgTmpl.csv" -NoTypeInformation
}

#Invoke-SRIntuneBackupNotificationTemplates -Path "C:\temp\IntuneBackup\FunctionTest"