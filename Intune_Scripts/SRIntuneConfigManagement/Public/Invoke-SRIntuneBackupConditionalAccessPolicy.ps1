function Invoke-SRIntuneBackupConditionalAccessPolicy {
    <#
    .SYNOPSIS
    Backup Intune Conditional Access Policy
     
    .DESCRIPTION
    Backup Intune Conditional Access Policies as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupConditionalAccessPolicy -Path "C:\temp"
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
    $Subfolder = "Conditional Access Policies"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get all Conditional Access policies
    $Uri = "$ApiVersion/identity/conditionalAccess/policies"
    $Policies = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
    
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

#Invoke-SRIntuneBackupConditionalAccessPolicy -Path "C:\temp\IntuneBackup\FunctionTest"