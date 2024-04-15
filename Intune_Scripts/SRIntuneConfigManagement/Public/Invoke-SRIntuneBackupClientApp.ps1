function Invoke-SRIntuneBackupClientApp {
    <#
    .SYNOPSIS
    Backup Intune Client Apps
    
    .DESCRIPTION
    Backup Intune Client Apps as JSON files per Device Compliance Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupClientApp -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Client Apps")) {
        $null = New-Item -Path "$Path\Client Apps" -ItemType Directory
    }

    # Get all Client Apps
    $Uri = "$ApiVersion/deviceAppManagement/mobileApps?$filter=(microsoft.graph.managedApp/appAvailability%20eq%20null%20or%20microsoft.graph.managedApp/appAvailability%20eq%20%27lineOfBusiness%27%20or%20isAssigned%20eq%20true)"
    $clientApps = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($clientApp in $clientApps) {
        $clientAppType = $clientApp.'@odata.type'.split('.')[-1]

        $fileName = ($clientApp.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $Uri = "$ApiVersion/deviceAppManagement/mobileApps/$($clientApp.id)"
        $clientAppDetails = Invoke-MgGraphRequest -Uri $Uri 
        $clientAppDetails | ConvertTo-Json | Out-File -LiteralPath "$path\Client Apps\$($clientAppType)_$($fileName).json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Client App"
            "Name"   = $clientApp.displayName
            "Path"   = "Client Apps\$($clientAppType)_$($fileName).json"
        }
    }
}

#Invoke-SRIntuneBackupClientApp -Path "C:\temp\IntuneBackup\FunctionTest"