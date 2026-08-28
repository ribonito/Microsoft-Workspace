<#
.SYNOPSIS
    UTL-027 | M365 Domain DNS Overview.

.DESCRIPTION
    Export DNS records required for M365 domain validation.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-027 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Tools/Get-M365DomainDnsOverview.ps1

.NOTES
    Name: UTL-027_Get-M365-Domain-Dns-Overview.ps1
    Integrated from O365scripts upstream repository.
#>

function Get-M365DomainDnsOverview {
	[CmdletBinding()] Param ($Domain=$null,$OutputMode="List",$PathOut=$null,$Server=$null)
	Begin {
		if ($null -eq $Domain) {
			Write-Host -Fore Red "MICROSOFT 365 DNS LOOKUP"
			$Domain = Read-Host -Prompt "Enter the domain name to lookup M365 related DNS records"
		}
	$ErrAct = "SilentlyContinue"
	}
	Process {
		if ($Domain -is [string] -and ($Domain).Length -gt 0) {
			$Domain 	= ($Domain).Trim()
			$DnsNS		= (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "NS" -Name $Domain).ForEach({$_[0].NameHost}) | Out-String
			$DnsA		= (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "A" -Name $Domain).ForEach({$_[0].IPAddress}) | Out-String
			$DnsMx		= (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "MX" -Name $Domain | sort Preference).ForEach({if ($null -ne $($_.NameExchange)) {"$($_.NameExchange) [$($_.Preference)]"}}) | Out-String
			$DnsTxt		= (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "TXT" -Name $Domain).ForEach({$_[0].Strings}) | Out-String
			$DnsDmarc	= (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "TXT" -Name _dmarc.$Domain).ForEach({$_[0].Strings}) | Out-String
			$DnsAuto	= (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "CNAME" -Name "autodiscover.$Domain").NameHost
			$DnsDkim1	= (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "CNAME" -Name "selector1._domainkey.$Domain").NameHost
			$DnsDkim2	= (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "CNAME" -Name "selector2._domainkey.$Domain").NameHost
			$DnsSfbLync	= (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "CNAME" -Name "lyncdiscover.$Domain").NameHost
			$DnsSfbLyncA = (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "A" -Name "lyncdiscover.$Domain").ForEach({$_[0].IPAddress}) | Out-String
			$DnsSfbSip = (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "CNAME" -Name "sip.$Domain").NameHost
			$DnsSfbSipA = (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "A" -Name "sip.$Domain").ForEach({$_[0].IPAddress}) | Out-String
			$DnsSfbSipSrv = (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "SRV" -Name "_sip._tls.$Domain").ForEach({if ($null -ne $_.NameTarget) {"$($_[0].NameTarget):$($_[0].Port)"}}) | Out-String
			$DnsSfbSipFedSrv = (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "SRV" -Name "_sipfederationtls._tcp.$Domain").ForEach({if ($null -ne $_.NameTarget) {"$($_[0].NameTarget):$($_[0].Port)"}}) | Out-String
			$DnsMdm1 	= (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "CNAME" -Name "enterpriseregistration.$Domain").NameHost
			$DnsMdm2 	= (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "CNAME" -Name "enterpriseenrollment.$Domain").NameHost
			$DnsSoa 	= (Resolve-Dnsname -Server $Server -ErrorAction $ErrAct -Type "CNAME" -Name "$Domain").NameAdministrator
			$Report = [System.Collections.Generic.List[Object]]::new()
			$ReportLine = [PSCustomObject] @{
				Domain = $Domain
				NS			= $DnsNS
				A			= $DnsA
				MX			= $DnsMx
				TXT			= $DnsTxt
				DMARC			= $DnsDmarc
				Autodiscover		= $DnsAuto
				DKIM1			= $DnsDkim1
				DKIM2			= $DnsDkim2
				SkypeLyncdiscover	= $DnsSfbLync
				SkypeLyncdiscoverA	= $DnsSfbLyncA
				SkypeSip		= $DnsSfbSip
				SkypeSipA		= $DnsSfbSipA
				SkypeSipSRV		= $DnsSfbSipSrv
				SkypeSipFedSRV		= $DnsSfbSipFedSrv
				MDM1			= $DnsMdm1
				MDM2			= $DnsMdm2
				SOA			= $DnsSoa
			}
			$Report.Add($ReportLine)
			if ($OutputMode -eq "List") {
				#Write-Host -Fore Red "MICROSOFT 365 DNS LOOKUP"
				Write-Host -Fore Yellow -NoNewline "Domain: "; Write-Host $Domain;
				Write-Host -Fore Green "DNS results"
				$Report # | Format-List
			}
			if ($OutputMode -eq "File") {$Report | Out-File -FilePath "$PathOut\Get-M365DomainDnsOverview_$((Get-Date -Format "yyyyMMddHHmmss")).txt" -Encoding utf8}
		}
		else {Write-Host -Fore Yellow "Nothing to lookup, closing."}
	}
}
