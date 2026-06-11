<#
.SYNOPSIS
    UTL-003 | Utility - Configure System Proxy and Force TLS 1.2 for PowerShell Sessions.

.DESCRIPTION
    Configures the current PowerShell session to use the system-defined proxy settings
    (from Internet Explorer / Windows proxy configuration) with the logged-on user's
    network credentials.

    Also enforces TLS 1.2 as the minimum security protocol for all outbound
    HTTPS connections from the session.

    This is typically needed in:
        - Corporate environments with a mandatory proxy
        - Environments where legacy TLS 1.0/1.1 is blocked
        - Automation scripts that connect to Microsoft 365 APIs behind a proxy

.PRODUCT
    Utility / Windows PowerShell Network Configuration

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    # Add this at the top of any script that runs behind a corporate proxy:
    . .\UTL-003_Set-ProxyAndTLS.ps1

.NOTES
    - No modules required
    - Must be run or dot-sourced at the START of the session before any network calls
    - Uses DefaultNetworkCredentials (Kerberos/NTLM passthrough)
    - TLS 1.2 is required for Microsoft Graph, Exchange Online, and all modern M365 APIs
#>

#region ── Proxy Configuration ────────────────────────────────────────────────
# Use the system-level proxy (Windows/IE proxy settings)
[System.Net.WebRequest]::DefaultWebProxy = [System.Net.WebRequest]::GetSystemWebProxy()

# Pass the current user's network credentials to the proxy (NTLM/Kerberos)
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
#endregion

#region ── TLS 1.2 Enforcement ────────────────────────────────────────────────
# Force TLS 1.2 for all outbound HTTPS connections in this session
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#endregion

Write-Host "Proxy: system proxy configured with default network credentials." -ForegroundColor Cyan
Write-Host "TLS  : minimum protocol set to TLS 1.2." -ForegroundColor Cyan
