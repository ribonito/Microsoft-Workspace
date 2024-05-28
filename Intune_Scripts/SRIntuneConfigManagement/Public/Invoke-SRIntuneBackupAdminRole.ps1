function Invoke-SRIntuneBackupAdminRole {
    <#
    .SYNOPSIS
    Backup Intune Admin role
    
    .DESCRIPTION
    Backup Intune Admin role as JSON files
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupAdminRole -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Admin Roles")) {
        $null = New-Item -Path "$Path\Admin Roles" -ItemType Directory
    }

    $AdminRoles = @{}
    # Get all custom Admin Roles
    $Uri = "$ApiVersion/deviceManagement/roledefinitions?`$filter=isBuiltIn eq false"
    $AdminRoles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($AdminRole in $AdminRoles) {
        $fileName = ($AdminRole.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $AdminRole | ConvertTo-Json -Depth 10 | Out-File -LiteralPath "$path\Admin Roles\$($fileName).json"
        #Store admin role name and id in a hash table
        $AdminRoles.Add($AdminRole.id, $AdminRole.displayName)

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Admin Role"
            "Name"   = $AdminRole.displayName
            "Path"   = "Admin Roles\$($fileName).json"
        }
    }
    #Store Admin Roles hash table in a CSV file
    $AdminRoles.GetEnumerator() | Select Key, Value | Export-CSV -path "$Path\Admin Roles\AdminRoles.csv" -NoTypeInformation
}

#Invoke-SRIntuneBackupAdminRole -Path "C:\temp\IntuneBackup\FunctionTest"