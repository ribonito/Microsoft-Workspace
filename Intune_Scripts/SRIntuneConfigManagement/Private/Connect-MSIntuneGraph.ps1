function Connect-MSIntuneGraph {
    <#
    .SYNOPSIS
        Get or refresh an access token using either authorization code flow or device code flow, that can be used to authenticate and authorize against resources in Graph API.

    .DESCRIPTION
        Get or refresh an access token using either authorization code flow or device code flow, that can be used to authenticate and authorize against resources in Graph API.

    .PARAMETER TenantID
        Specify the tenant name or ID, e.g. tenant.onmicrosoft.com or <GUID>.
    #>
    [CmdletBinding(DefaultParameterSetName = "Interactive")]
    param(
        [parameter(Mandatory = $true)]
        [string]$TenantID
    )
    try {
                
        # Attempt to retrieve an access token from MgGraph session
        #Connect-MgGraph -tenantid $TenantID -Scopes DeviceManagementManagedDevices.PrivilegedOperations.All,DeviceManagementManagedDevices.ReadWrite.All,DeviceManagementRBAC.ReadWrite.All,DeviceManagementApps.ReadWrite.All,DeviceManagementConfiguration.ReadWrite.All,DeviceManagementServiceConfig.ReadWrite.All,Group.ReadWrite.All,GroupMember.ReadWrite.All,Directory.ReadWrite.All,RoleManagement.ReadWrite.Directory,Policy.Read.All,Policy.ReadWrite.ConditionalAccess,Application.ReadWrite.All
        $mgRequest = Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/me" -OutputType HttpResponseMessage
    
        $Global:AccessToken = $mgRequest.RequestMessage.Headers.Authorization.Parameter
        $Global:AccessTokenTenantID = $TenantID
        Write-Verbose -Message "Successfully retrieved access token"
                
        try {
            # Construct the required authentication header
            $Global:AuthenticationHeader = @{
                "Content-Type" = "application/json"
                "Authorization" = "$($mgRequest.RequestMessage.Headers.Authorization.Scheme) $($mgRequest.RequestMessage.Headers.Authorization.Parameter)"
            }

            Write-Verbose -Message "Successfully constructed authentication header"

            # Handle return value
            return $Global:AuthenticationHeader
        } catch [System.Exception] {
            Write-Warning -Message "An error occurred while attempting to construct authentication header. Error message: $($PSItem.Exception.Message)"
        }
    } catch [System.Exception] {
        Write-Warning -Message "An error occurred while attempting to retrieve or refresh access token. Error message: $($PSItem.Exception.Message)"
    }
}