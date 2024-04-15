function Invoke-SRIntuneBackupClientAppAssignment {
    <#
    .SYNOPSIS
    Backup Intune Client App Assignments
    
    .DESCRIPTION
    Backup Intune Client App  Assignments as JSON files per Client App to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupClientAppAssignment -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Client Apps\Assignments")) {
        $null = New-Item -Path "$Path\Client Apps\Assignments" -ItemType Directory
    }

    # Get all assignments from all policies
    $Uri = "$ApiVersion/deviceAppManagement/mobileApps?$filter=(microsoft.graph.managedApp/appAvailability%20eq%20null%20or%20microsoft.graph.managedApp/appAvailability%20eq%20%27lineOfBusiness%27%20or%20isAssigned%20eq%20true)"
    $clientApps = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
   
    foreach ($clientApp in $clientApps) {
        $Uri = "$ApiVersion/deviceAppManagement/mobileApps/$($clientApp.id)/assignments"
        $assignments = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        if ($assignments) {
            $fileName = ($clientApp.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
            $assignments | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Client Apps\Assignments\$($clientApp.id) - $fileName.json"

            [PSCustomObject]@{
                "Action" = "Backup"
                "Type"   = "Client App Assignments"
                "Name"   = $clientApp.displayName
                "Path"   = "Client Apps\Assignments\$fileName.json"
            }
        }
    }
}

#Invoke-SRIntuneBackupClientAppAssignment -Path "C:\temp\IntuneBackup\FunctionTest"