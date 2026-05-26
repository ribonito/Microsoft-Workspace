function Invoke-SRIntuneBackupTenantInfo {
    <#
    .SYNOPSIS
    Backup Tenant information
     
    .DESCRIPTION
    Backup Intune tenant infdormation to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupTenantInfo -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [string]$Prefix,
        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Create folder if not exists
    $Subfolder = "Tenant Info"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get tenant details
    $Uri = "v1.0/organization?`$select=id,displayname"
    $Org = $(Invoke-MgGraphRequest -Uri $Uri).Value

    $TenantInfo = @{$($Org.displayName) = $($Org.id)}    

    #Store group hash table in a CSV file
    $TenantInfo.GetEnumerator() | Select Key, Value | Export-CSV -path "$Path\$Subfolder\TenantInfo.csv" -NoTypeInformation
}

#Invoke-SRIntuneBackupTenantInfo -Path "C:\temp\IntuneBackup\FunctionTest"