function Invoke-SRIntuneBackupGroupPolicyConfiguration {
    <#
    .SYNOPSIS
    Backup Intune Group Policy Configurations
    
    .DESCRIPTION
    Backup Intune Group Policy Configurations as JSON files per Group Policy Configuration Policy to the specified Path.
    
    .PARAMETER Path
    Path to store backup files
    
    .EXAMPLE
    Invoke-SRIntuneBackupGroupPolicyConfiguration -Path "C:\temp"
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
    if (-not (Test-Path "$Path\Administrative Templates")) {
        $null = New-Item -Path "$Path\Administrative Templates" -ItemType Directory
    }

    $IsCustom = $false
    # Get all Group Policy Configurations
    $Uri = "$ApiVersion/deviceManagement/groupPolicyConfigurations"
    $groupPolicyConfigurations = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages

    foreach ($groupPolicyConfiguration in $groupPolicyConfigurations) {
        if($($groupPolicyConfiguration.policyConfigurationIngestionType) -eq "custom") {$IsCustom = $true}
        $Uri = "$ApiVersion/deviceManagement/groupPolicyConfigurations/$($groupPolicyConfiguration.id)/definitionValues"
        $groupPolicyDefinitionValues = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        $groupPolicyBackupValues = @{
            "Policy" = $groupPolicyConfiguration
            "Definitions" = @()
        }

        foreach ($groupPolicyDefinitionValue in $groupPolicyDefinitionValues) {
            $Uri = "$ApiVersion/deviceManagement/groupPolicyConfigurations/$($groupPolicyConfiguration.id)/definitionValues/$($groupPolicyDefinitionValue.id)/definition"
            $groupPolicyDefinition = Invoke-MgGraphRequest -Uri $Uri
            $Uri = "$ApiVersion/deviceManagement/groupPolicyConfigurations/$($groupPolicyConfiguration.id)/definitionValues/$($groupPolicyDefinitionValue.id)/presentationValues?`$expand=presentation"
            $groupPolicyPresentationValues = Invoke-MgGraphRequest -Uri $Uri | Select-Object -Property * -ExcludeProperty lastModifiedDateTime, createdDateTime
            $groupPolicyBackupValue = @{
                "enabled" = $groupPolicyDefinitionValue.enabled
                "definition@odata.bind" = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('$($groupPolicyDefinition.id)')"
            }

            foreach ($groupPolicyPresentationValue in $groupPolicyPresentationValues.Values) {
                if($groupPolicyPresentationValue -and $groupPolicyPresentationValue -notmatch "https://graph.microsoft.com"){
                    
                    $groupPolicyBackupValue."presentationValues" = @()
                    if ($groupPolicyPresentationValue.value) {
                    $groupPolicyBackupValue."presentationValues" +=
                        @{
                            "value" = $groupPolicyPresentationValue.value
                            "@odata.type" = $groupPolicyPresentationValue.'@odata.type'
                            "presentation@odata.bind" = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('$($groupPolicyDefinition.id)')/presentations('$($groupPolicyPresentationValue.presentation.id)')"
                            "label" = $($groupPolicyPresentationValue.presentation.label)
                        }
                    } elseif ($groupPolicyPresentationValue.values){
                    $groupPolicyBackupValue."presentationValues" +=
                        @{
                            "values" = $groupPolicyPresentationValue.values
                            "@odata.type" = $groupPolicyPresentationValue.'@odata.type'
                            "presentation@odata.bind" = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('$($groupPolicyDefinition.id)')/presentations('$($groupPolicyPresentationValue.presentation.id)')"
                            "label" = $($groupPolicyPresentationValue.presentation.label)
                        }
                    }
                }
            }
            $groupPolicyBackupValues."Definitions" += $groupPolicyBackupValue
        }

        $fileName = ($groupPolicyConfiguration.displayName).Split([IO.Path]::GetInvalidFileNameChars()) -join '_'
        $groupPolicyBackupValues | ConvertTo-Json -Depth 100 | Out-File -LiteralPath "$path\Administrative Templates\$fileName.json"

        [PSCustomObject]@{
            "Action" = "Backup"
            "Type"   = "Administrative Template"
            "Name"   = $groupPolicyConfiguration.displayName
            "Path"   = "Administrative Templates\$fileName.json"
        }
    }

    #Store group name, type and id in a hash table
    if($IsCustom){
            
        # Get all Group Policy Configurations
        $DefExport = @()
        $Uri = "$ApiVersion/deviceManagement/groupPolicyDefinitions?`$filter=policyType eq 'admxIngested'&`$select=id,categoryPath,displayName"
        $definitions = Invoke-MgGraphRequest -Uri $Uri | Get-MgGraphAllPages
        foreach ($definition in $definitions){
            $row = "" | Select-Object id,categoryPath,displayName
            $row.id = $definition.id
            $row.categoryPath = $definition.categoryPath  
            $row.displayName = $definition.displayName
            $DefExport += $row
        }
        $DefExport | Export-CSV -path "$Path\Administrative Templates\Definitions.csv" -NoTypeInformation -Encoding UTF8
    }
}

#Invoke-SRIntuneBackupGroupPolicyConfiguration -Path "C:\temp\IntuneBackup\FunctionTest"