function Invoke-SRIntuneBackupBrandingProfiles {
    <#
    .SYNOPSIS
    Backup Intune Branding profiles
     
    .DESCRIPTION
    Backup Intune branding profiles as JSON files per profile item to the specified Path.
     
    .PARAMETER Path
    Path to store backup files
     
    .EXAMPLE
    Invoke-SRIntuneBackupBrandingProfiles -Path "C:\temp"
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
    $Subfolder = "Branding profiles"
    if (-not (Test-Path "$Path\$Subfolder")) {
        $null = New-Item -Path "$Path\$Subfolder" -ItemType Directory
    }

    # Get ids of all profiles
    $Uri = "$ApiVersion/deviceManagement/intuneBrandingProfiles?`select=id"
    $Profiles = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($Profile in $Profiles) {
        # get profile (images are not returned. they must be retrieved property by property)
        $Uri = "$ApiVersion/deviceManagement/intuneBrandingProfiles/$($Profile.id)"
        $FullProfile = Invoke-MgGraphRequest -Uri $Uri

        $Uri = "$ApiVersion/deviceManagement/intuneBrandingProfiles/$($Profile.id)?`$select=themeColorLogo"
        $image = Invoke-MgGraphRequest -Uri $Uri
        if ($($image.themeColorLogo)){$FullProfile.themeColorLogo = $image.themeColorLogo }

        $Uri = "$ApiVersion/deviceManagement/intuneBrandingProfiles/$($Profile.id)?`$select=lightBackgroundLogo"
        $image = Invoke-MgGraphRequest -Uri $Uri
        if ($($image.lightBackgroundLogo)){$FullProfile.lightBackgroundLogo = $image.lightBackgroundLogo }
        
        $Uri = "$ApiVersion/deviceManagement/intuneBrandingProfiles/$($Profile.id)?`$select=landingPageCustomizedImage"
        $image = Invoke-MgGraphRequest -Uri $Uri
        if ($($image.landingPageCustomizedImage)){$FullProfile.landingPageCustomizedImage = $image.landingPageCustomizedImage }

        $fileName = ($FullProfile.profileName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $FullProfile | ConvertTo-Json -Depth 10 | Out-File -LiteralPath "$path\$Subfolder\$($fileName).json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Branding Profiles"
            "Name"   = $FullProfile.profileName
            "Path"   = "$Subfolder\$($fileName).json"
        }
    }
}

#Invoke-SRIntuneBackupBrandingProfiles -Path "C:\temp\IntuneBackup\FunctionTest"