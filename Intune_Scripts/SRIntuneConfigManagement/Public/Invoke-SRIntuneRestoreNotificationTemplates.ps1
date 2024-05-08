function Invoke-SRIntuneRestoreNotificationTemplates {
    <#
    .SYNOPSIS
    Restore Intune Notification message templates
    
    .DESCRIPTION
    Restore Intune Notification message templates from JSON files in the specified Path.
    
    .PARAMETER Path
    Root path where backup files are located
    
    .PARAMETER SourceScopeTags
    Hashtable containing scope tag names and ids imported from source backup
    
    .PARAMETER SameTenant
    True if source tenant is the same as target, otherwise false
    
    .EXAMPLE
    Invoke-SRIntuneRestoreNotificationTemplates -Path "C:\temp"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $false)]
        [hashtable]$SourceScopeTags,
        [Parameter(Mandatory = $false)]
        [boolean]$SameTenant = $false,
        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    # Check if restore folder exists
    if (-not (Test-Path "$Path\Notification templates")) {
        Write-Warning "Folder '$Path\Notification templates' doesn't exist. Skipping restore of Notification templates"
        Return
    }

    #Get Source tenant scope tags
    If (-not $SourceScopeTags) {
    $SourceScopeTags = Import-SRSScopeTagsFromCSV -Path "$Path"
    }

    # Get all notification templates
    $Templates = Get-ChildItem -Path "$Path\Notification templates\*" -Include *.json
    foreach ($Template in $Templates) {
        $TemplateContent = Get-Content -LiteralPath $Template.FullName -Raw
        $TemplateDisplayName = ($TemplateContent | ConvertFrom-Json).displayName

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject = $TemplateContent | ConvertFrom-Json
        if ($requestBodyObject.roleScopeTagIds -and -not($SameTenant)) {
            $i = 0
            foreach ($ScopeTagIdJson in $requestBodyObject.roleScopeTagIds) {
                if($ScopeTagIdJson -ne "0"){
                    # Replace scope tag IDs in the json with the ids in the target tenant based on scope name
                    $ScopeTagNameCsv = $null
                    $TargetScopeTagId = $null
                    $ScopeTagNameCsv = ($SourceScopeTags.GetEnumerator() | Where-Object {$_.Name -eq $ScopeTagIdJson}).Value
                    if($ScopeTagNameCsv){$TargetScopeTagId = Get-SRScopeTagId -ScopeTagName $ScopeTagNameCsv}
                    if($TargetScopeTagId){$requestBodyObject.roleScopeTagIds[$i] = $TargetScopeTagId}
                }
                $i = $i+1
            }
        }

        # Remove properties that are not available for creating a new configuration
        $requestBodyObject.PSObject.Properties | Foreach-Object {
            if ($null -ne $_.Value) {
                if ($_.Value.GetType().Name -eq "DateTime") {
                    $_.Value = (Get-Date -Date $_.Value -Format s) + "Z"
                }
            }
            if ($_.Name -eq "localizedNotificationMessages") {
                $_.Value = $_.Value | select * -ExcludeProperty id,lastModifiedDateTime
            }
        }

        # If missing, adds @odata.type property required for restoring configuration.
        if (-not ($requestBodyObject.'@odata.type')) {
            $requestBodyObject | Add-Member -NotePropertyName '@odata.type' -NotePropertyValue "#microsoft.graph.notificationMessageTemplate"
        }

        $requestBody = $requestBodyObject | Select-Object -Property * -ExcludeProperty id, lastModifiedDateTime, 'localizedNotificationMessages@odata.context',localizedNotificationMessages,description,roleScopeTagIds | ConvertTo-Json -Depth 100
        #$requestBody
        # Restore the Device Compliance Policy
        try {
            $Uri = "$ApiVersion/deviceManagement/notificationMessageTemplates"
            $null = Invoke-MgGraphRequest -Method POST -Body $requestBody.toString() -Uri $Uri -ContentType "application/json" -ErrorAction Stop
            [PSCustomObject]@{
                "Action" = "Restore"
                "Type"   = "Notification message template"
                "Name"   = $TemplateDisplayName
                "Path"   = "Notification templates\$($Template.Name)"
            }
        }
        catch {
            Write-Verbose "$TemplateDisplayName - Failed to restore Notification message template" -Verbose
            Write-Error $_ -ErrorAction Continue
        }
    }
}

#Invoke-SRIntuneRestoreNotificationTemplates -Path "C:\temp\Intunerestore"