<#
.SYNOPSIS
    Interactive DNS diagnostic tool for validating Microsoft 365 domain records.

.DESCRIPTION
    Prompts for a custom domain name and tests for all expected Microsoft 365 DNS records,
    including MX, SPF/TXT, Autodiscover, DKIM selectors, Microsoft Teams / Skype for Business
    CNAME and SRV records, and Intune MDM enrollment endpoints.

.NOTES
    Requires the built-in DnsClient PowerShell module.
    Ensure internet connectivity to standard public DNS resolvers.

.EXAMPLE
    .\M365 DNS Overview.ps1
    Launches the interactive DNS assessment console for Microsoft 365 domains.

.LINK
    https://learn.microsoft.com/microsoft-365/admin/get-help-with-domains/create-dns-records-at-any-dns-hosting-provider
    https://learn.microsoft.com/microsoft-365/security/office-365-security/email-authentication-dkim-configure
#>

[CmdletBinding()]
param ()

# Feature toggle flags
$CheckExo   = 1
$CheckTeams = 1
$CheckMdm   = 1

do {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "       MICROSOFT 365 DNS DIAGNOSTICS      " -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Cyan

    $domain = Read-Host -Prompt "`nEnter domain to audit (or press Enter to exit)"
    if ([string]::IsNullOrWhiteSpace($domain)) {
        Write-Host "Exiting DNS overview tool." -ForegroundColor Gray
        break
    }

    Write-Host "`nResolving records for: $domain..." -ForegroundColor Cyan

    # 1. Exchange Online Records (MX, Autodiscover, DKIM, TXT/SPF)
    if ($CheckExo) {
        $dns_mx    = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "MX" -Name $domain | Sort-Object Preference).ForEach({ "$($_.NameExchange) [Priority: $($_.Preference)]" }) -join "; "
        $dns_auto  = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "CNAME" -Name "autodiscover.$domain").NameHost
        $dns_dkim1 = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "CNAME" -Name "selector1._domainkey.$domain").NameHost
        $dns_dkim2 = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "CNAME" -Name "selector2._domainkey.$domain").NameHost
        $dns_txt   = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "TXT" -Name $domain).ForEach({ $_.Strings -join " " }) -join "`n    "
    }

    # 2. Microsoft Teams / Skype for Business Records (CNAME & SRV)
    if ($CheckTeams) {
        $dns_sfb1    = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "CNAME" -Name "lyncdiscover.$domain").NameHost
        $dns_sfb2    = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "CNAME" -Name "sip.$domain").NameHost
        $dns_sfbsrv1 = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "SRV" -Name "_sip._tls.$domain").ForEach({ "$($_.NameTarget):$($_.Port)" }) -join "; "
        $dns_sfbsrv2 = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "SRV" -Name "_sipfederationtls._tcp.$domain").ForEach({ "$($_.NameTarget):$($_.Port)" }) -join "; "
    }

    # 3. MDM Intune Device Enrollment Records (CNAME)
    if ($CheckMdm) {
        $dns_mdm1 = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "CNAME" -Name "enterpriseregistration.$domain").NameHost
        $dns_mdm2 = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "CNAME" -Name "enterpriseenrollment.$domain").NameHost
    }

    # Print results
    Write-Host "`n--- Exchange Online & Mail Flow ---" -ForegroundColor Yellow
    Write-Host "MX Records:     $dns_mx"
    Write-Host "Autodiscover:   $dns_auto"
    Write-Host "DKIM 1:         $dns_dkim1"
    Write-Host "DKIM 2:         $dns_dkim2"
    Write-Host "TXT / SPF:`n    $dns_txt"

    Write-Host "`n--- Teams & Skype for Business ---" -ForegroundColor Yellow
    Write-Host "LyncDiscover:   $dns_sfb1"
    Write-Host "SIP CNAME:      $dns_sfb2"
    Write-Host "SIP TLS SRV:    $dns_sfbsrv1"
    Write-Host "Federation SRV: $dns_sfbsrv2"

    Write-Host "`n--- Intune MDM Registration ---" -ForegroundColor Yellow
    Write-Host "EnterpriseRegistration: $dns_mdm1"
    Write-Host "EnterpriseEnrollment:   $dns_mdm2"

    Write-Host "`n==========================================" -ForegroundColor Cyan
    $repeat = Read-Host -Prompt "Audit another domain? (y/n)"
} while ($repeat -like "y*")
