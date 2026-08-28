<#
.SYNOPSIS
    UTL-032 | M365 Bulk Domain Overview.

.DESCRIPTION
    Bulk domain status overview across tenants.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-032 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Tools/M365%20Bulk%20Domain%20Overview.ps1

.NOTES
    Name: UTL-032_M365-Bulk-Domain-Overview.ps1
    Integrated from O365scripts upstream repository.
#>

function Get-M365BulkDomainDnsOverview {
	[CmdletBinding()] Param (
		$Domains=$null,
		$PathExport="$env:USERPROFILE\Downloads";
		);
Begin {
	if (!$Domains) {
		Write-Host "No domains to lookup, closing.";
		Break;
	}
	$Report = [System.Collections.Generic.List[Object]]::new();
	$StampNow = Get-Date -Format "yyyyMMddhhmmss";
}
Process {
<# Build a report of the general DNS and Office 365-related records of selected domains. #>
$Domains | % {
	$DnsNS		= (Resolve-Dnsname -DnsOnly -ErrorAction SilentlyContinue -Type "NS" -Name $_).ForEach({$_[0].NameHost}) | Out-String;
	$DnsA		= (Resolve-Dnsname -DnsOnly -ErrorAction SilentlyContinue -Type "A" -Name $_).ForEach({$_[0].IPAddress}) | Out-String;
	$DnsMx		= (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "MX" -Name $_ | sort Preference).ForEach({"$($_.NameExchange) [$($_.Preference)]"}) | Out-String;
	$DnsTxt		= (Resolve-Dnsname -DnsOnly -ErrorAction SilentlyContinue -Type "TXT" -Name $_).ForEach({$_[0].Strings}) | Out-String;
	$DnsAuto	= (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "autodiscover.$_").NameHost;
	$DnsDkim1	= (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "selector1._domainkey.$_").NameHost;
	$DnsDkim2	= (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "selector2._domainkey.$_").NameHost;
	$DnsSfb1	= (Resolve-Dnsname -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "lyncdiscover.$_").NameHost;
	$DnsSfb2	= (Resolve-Dnsname -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "sip.$_").NameHost;
	$DnsSfbSrv1	= (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "SRV" -Name "_sip._tls.$_").ForEach({if ("" -ne $_.NameTarget) {"$($_[0].NameTarget):$($_[0].Port)"}}) | Out-String;
	$DnsSfbSrv2	= (Resolve-DnsName -DnsOnly -ErrorAction SilentlyContinue -Type "SRV" -Name "_sipfederationtls._tcp.$_").ForEach({if ("" -ne $_.NameTarget) {"$($_[0].NameTarget):$($_[0].Port)"}}) | Out-String;
	$DnsMdm1 	= (Resolve-Dnsname -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "enterpriseregistration.$_").NameHost;
	$DnsMdm2 	= (Resolve-Dnsname -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "enterpriseenrollment.$_").NameHost;
	$DnsSoa 	= (Resolve-Dnsname -DnsOnly -ErrorAction SilentlyContinue -Type "CNAME" -Name "$_").NameAdministrator;
	$ReportLine = [PSCustomObject] @{
		Domain = $_
		NS = $DnsNS
		A = $DnsA
		MX = $DnsMx
		TXT = $DnsTxt
		Autodiscover = $DnsAuto
		DKIM_1 = $DnsDkim1
		DKIM_2 = $DnsDkim2
		SkypeCNAME_1 = $DnsSfb1
		SkypeCNAME_2 = $DnsSfb2
		SkypeSRV_1 = $DnsSfbSrv1
		SkypeSRV_2 = $DnsSfbSrv2
		MDM_1 = $DnsMdm1
		MDM_2 = $DnsMdm2
		SOA = $DnsSoa
	};
	$Report.Add($ReportLine);
	}
}
End {
	if ($ExportReport) {
		Write-Host;
		$Report | Export-Csv "$PathExport\M365BulkDomainDnsOverview_$StampNow.csv" -Encoding utf8 -NoTypeInformation -Verbose;
	}
	Return $Report;
}
}

<# Example: Manual list. #>
$ListDomains = "hotmail.com", "live.com", "msn.com"; # Specify manually the list of domains to lookup the DNS records?
Get-M365BulkDomainDnsOverview -Domains $ListDomains;

<# Example: #>
$ListDomains = (Read-Host -Prompt "Enter domains to lookup DNS (separated by space)").Split(" "); # Prompt directly for domains to lookup?
Get-M365BulkDomainDnsOverview -Domains $ListDomains;

<# Example: #>
$ListDomains = Get-Content -Path "$env:USERPROFILE\Desktop\List of Domains.txt"; # Pull domains from file? (single column, no header)
Get-M365BulkDomainDnsOverview -Domains $ListDomains;
