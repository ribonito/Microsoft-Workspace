function Get-SRNotificationTemplateId.ps1 {
    <#
    .SYNOPSIS
    Get Notification template id from name
     
    .DESCRIPTION
    Get Notification template id from name
     
    .PARAMETER FilterName
    String. Name of the Notification template
     
    .EXAMPLE
    Get-SRNotificationTemplateId.ps1 -NotificationName "iOS managed"
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$NotificationName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("v1.0", "Beta")]
        [string]$ApiVersion = "Beta"
    )

    $QueryFilter = "?`$select=id,displayName"

    # Get the group id passing the name
    $Uri = "$ApiVersion/deviceManagement/notificationMessageTemplates$QueryFilter"
    $NotificationId = $($(Invoke-MgGraphRequest -Uri $Uri).Value | Where-Object {$_.displayName -eq $NotificationName}).id
    Return $NotificationId
}

#Get-SRNotificationTemplateId.ps1 -NotificationName "SRMW-Win-ComplMsg-OS"