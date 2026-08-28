<#
.SYNOPSIS
    UTL-033 | M365 DNS Overview.

.DESCRIPTION
    Compare tenant DNS records against Microsoft requirements.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-033 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Tools/M365%20DNS%20Overview.ps1

.NOTES
    Name: UTL-033_M365-DNS-Overview.ps1
    Integrated from O365scripts upstream repository.
#>

<# Interactive M365 DNS lookup start. #>
$m365_gcc   = 0;
$m365_exo   = 1;
$m365_teams = 1;
$m365_mdm   = 1;

<# Interactive M365 DNS lookup v0.4 #>
do {
Clear
Write-Host -Fore Red "M365 DNS OVERVIEW";
$domain = Read-Host -Prompt "Enter domain";
if (!$domain) {exit;}
else
    {
    if ($m365_exo) {
        <# MX, CNAME, TXT #>
        $dns_mx = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "MX" -Name $Domain | sort Preference).ForEach({"$($_.NameExchange) [$($_.Preference)]"}) | Out-String;
        $dns_dkim1 = (Resolve-DnsName -Type "CNAME" -Name "selector1._domainkey.${domain}" -ErrorAction SilentlyContinue).NameHost;
        $dns_dkim2 = (Resolve-DnsName -Type "CNAME" -Name "selector2._domainkey.${domain}" -ErrorAction SilentlyContinue).NameHost;
        $dns_auto = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "CNAME" -Name "autodiscover.${domain}").NameHost;
        $dns_txt = (Resolve-Dnsname -ErrorAction SilentlyContinue -Type "TXT" -Name $Domain).ForEach({$_[0].Strings}) | Out-String;
        #$dns_dmarc = ();
        }
    if ($m365_teams) {
        $dns_sfb1 = (Resolve-Dnsname -ErrorAction SilentlyContinue -Type "CNAME" -Name "lyncdiscover.${domain}").NameHost;
        $dns_sfb2 = (Resolve-Dnsname -ErrorAction SilentlyContinue -Type "CNAME" -Name "sip.${domain}").NameHost;
        $dns_sfbsrv1 = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "SRV" -Name "_sip._tls.${domain}");
        $dns_sfbsrv2 = (Resolve-DnsName -ErrorAction SilentlyContinue -Type "SRV" -Name "_sipfederationtls._tcp.${domain}");
        }
    if ($m365_mdm) {
        $dns_mdm1 = (Resolve-Dnsname -ErrorAction SilentlyContinue -Type "CNAME" -Name "enterpriseregistration.${domain}").NameHost;
        $dns_mdm2 = (Resolve-Dnsname -ErrorAction SilentlyContinue -Type "CNAME" -Name "enterpriseenrollment.${domain}").NameHost;
        }
    }
Write-Host;
Write-Host -Fore Green "DNS results";
Write-Host -NoNewline -Fore Yellow "Autodiscover: "; Write-Host $dns_auto;
Write-Host -NoNewline -Fore Yellow "DKIM 1: "; Write-Host $dns_dkim1;
Write-Host -NoNewline -Fore Yellow "DKIM 2: "; Write-Host $dns_dkim2;
Write-Host -NoNewline -Fore Yellow "MDM 1: "; Write-Host $dns_mdm1;
Write-Host -NoNewline -Fore Yellow "MDM 2: "; Write-Host $dns_mdm2;
Write-Host -NoNewline -Fore Yellow "SFB CNAME 1: "; Write-Host $dns_sfb1;
Write-Host -NoNewline -Fore Yellow "SFB CNAME 2: "; Write-Host $dns_sfb2;
Write-Host -NoNewline -Fore Yellow "SFB SRV 1: "; $dns_sfbsrv1.NameTarget + ":" + $dns_sfbsrv1.Port
Write-Host -NoNewline -Fore Yellow "SFB SRV 2: "; $dns_sfbsrv2.NameTarget + ":" + $dns_sfbsrv2.Port
Write-Host -Fore Green "TXT records: "; [string]$dns_txt;
Write-Host -Fore Green "MX records: "; $dns_mx;
Write-Host -Fore Red "===============";
$doitagain = Read-Host -Prompt "Do you wish to lookup another domain? <y/n>";
}
while ($doitagain -like "y*")
