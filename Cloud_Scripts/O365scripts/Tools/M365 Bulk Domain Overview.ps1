<#
.SYNOPSIS
    Queries and audits critical DNS records for a bulk list of domains in Microsoft 365.

.DESCRIPTION
    Iterates through a list of custom domains and queries standard DNS records (NS, A, MX, TXT)
    as well as Microsoft 365 specific records (Autodiscover, DKIM selectors, Skype for Business / Teams
    CNAME and SRV records, MDM Intune enrollment CNAMEs, and SOA). Compiles findings into a structured
    report with optional CSV export.

.PARAMETER Domains
    Specifies an array of domain names to resolve and audit.

.PARAMETER PathExport
    The target directory where the CSV report will be saved if -ExportReport is specified.
    Defaults to the current user's Downloads folder.

.PARAMETER ExportReport
    Switch to indicate whether the resulting report should be exported to CSV.

.EXAMPLE
    Get-M365BulkDomainDnsOverview -Domains @("contoso.com", "fabrikam.com") -ExportReport
    Queries DNS records for the specified domains and exports results to CSV.

.EXAMPLE
    "contoso.com", "tailspintoys.com" | Get-M365BulkDomainDnsOverview
    Passes domains through the pipeline and displays the report in the console.

.NOTES
    Requires the DnsClient module (built into Windows 10/11 and Windows Server).
    Domains can be supplied manually, via pipeline, or imported from a text/CSV file.

.LINK
    https://learn.microsoft.com/powershell/module/dnsclient/resolve-dnsname
    https://learn.microsoft.com/microsoft-365/admin/get-help-with-domains/create-dns-records-at-any-dns-hosting-provider
#>
function Get-M365BulkDomainDnsOverview {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0, HelpMessage = "List of domain names to query.")]
        [string[]]$Domains,

        [Parameter(Mandatory = $false, HelpMessage = "Destination folder path for the exported CSV report.")]
        [string]$PathExport = "$env:USERPROFILE\Downloads",

        [Parameter(Mandatory = $false, HelpMessage = "Switch to enable automatic CSV export of results.")]
        [switch]$ExportReport
    )

    begin {
        if (-not $Domains -or $Domains.Count -eq 0) {
            Write-Warning "No domains specified to perform DNS lookup."
            return
        }
        $Report = [System.Collections.Generic.List[Object]]::new()
        $StampNow = Get-Date -Format "yyyyMMddHHmmss"
    }

    process {
        # Build report of DNS and Microsoft 365 records for each domain
        foreach ($domain in $Domains) {
            Write-Verbose "Resolving DNS records for domain: $domain"

            $DnsNS     = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "NS" -Name $domain).ForEach({ $_.NameHost }) -join "; "
            $DnsA      = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "A" -Name $domain).ForEach({ $_.IPAddress }) -join "; "
            $DnsMx     = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "MX" -Name $domain | Sort-Object Preference).ForEach({ "$($_.NameExchange) [$($_.Preference)]" }) -join "; "
            $DnsTxt    = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "TXT" -Name $domain).ForEach({ $_.Strings -join " " }) -join " | "
            $DnsAuto   = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "autodiscover.$domain").NameHost
            $DnsDkim1  = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "selector1._domainkey.$domain").NameHost
            $DnsDkim2  = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "selector2._domainkey.$domain").NameHost
            $DnsSfb1   = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "lyncdiscover.$domain").NameHost
            $DnsSfb2   = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "sip.$domain").NameHost
            $DnsSfbSrv1 = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "SRV" -Name "_sip._tls.$domain").ForEach({ if ($_.NameTarget) { "$($_.NameTarget):$($_.Port)" } }) -join "; "
            $DnsSfbSrv2 = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "SRV" -Name "_sipfederationtls._tcp.$domain").ForEach({ if ($_.NameTarget) { "$($_.NameTarget):$($_.Port)" } }) -join "; "
            $DnsMdm1   = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "enterpriseregistration.$domain").NameHost
            $DnsMdm2   = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "enterpriseenrollment.$domain").NameHost
            $DnsSoa    = (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "SOA" -Name $domain).NameAdministrator

            $ReportLine = [PSCustomObject]@{
                Domain       = $domain
                NS           = $DnsNS
                A            = $DnsA
                MX           = $DnsMx
                TXT          = $DnsTxt
                Autodiscover = $DnsAuto
                DKIM_1       = $DnsDkim1
                DKIM_2       = $DnsDkim2
                SkypeCNAME_1 = $DnsSfb1
                SkypeCNAME_2 = $DnsSfb2
                SkypeSRV_1   = $DnsSfbSrv1
                SkypeSRV_2   = $DnsSfbSrv2
                MDM_1        = $DnsMdm1
                MDM_2        = $DnsMdm2
                SOA          = $DnsSoa
            }
            $Report.Add($ReportLine)
        }
    }

    end {
        if ($ExportReport) {
            if (-not (Test-Path -Path $PathExport)) {
                New-Item -ItemType Directory -Path $PathExport -Force | Out-Null
            }
            $CsvFile = Join-Path -Path $PathExport -ChildPath "M365BulkDomainDnsOverview_$StampNow.csv"
            $Report | Export-Csv -Path $CsvFile -Encoding utf8 -NoTypeInformation
            Write-Host "Export completed: $CsvFile" -ForegroundColor Green
        }
        return $Report
    }
}

# Example usage (uncomment as needed):
# $ListDomains = @("hotmail.com", "live.com", "msn.com")
# Get-M365BulkDomainDnsOverview -Domains $ListDomains -ExportReport
