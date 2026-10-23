<#
.SYNOPSIS
    Searches message trace logs for unique external recipient addresses in Exchange Online.

.DESCRIPTION
    Connects to Exchange Online and audits message trace events over the last 30 days.
    Filters out messages sent to internal accepted domains (including *.onmicrosoft.com),
    identifies all unique external recipient email addresses, and exports the findings to CSV.

.NOTES
    Requires the ExchangeOnlineManagement module (v2 or v3).
    Update $AdminUpn, $Domain, and $DomainOnms with your organization's domain values.

.LINK
    https://learn.microsoft.com/powershell/module/exchange/get-messagetrace
#>

# Connect to Exchange Online
$AdminUpn = ""
if ([string]::IsNullOrWhiteSpace($AdminUpn)) {
    Connect-ExchangeOnline
} else {
    Connect-ExchangeOnline -UserPrincipalName $AdminUpn
}

# -----------------------------------------------------------------------------
# Scenario 1: Filter external recipients with a single primary domain
# -----------------------------------------------------------------------------
$Domain = "domain.com"
$DomainOnms = "tenant.onmicrosoft.com"
$PathCsvSingle = "$env:USERPROFILE\Desktop\ExportMsgTraceUniqueExternalAddresses_$((Get-Date -Format 'yyyyMMddHHmmss')).csv"

Write-Host "Querying message trace for single primary domain filter..." -ForegroundColor Cyan
Get-MessageTrace -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) |
    Where-Object {
        $_.RecipientAddress -notlike "*$Domain" -and
        $_.RecipientAddress -notlike "*$DomainOnms"
    } |
    Group-Object -Property RecipientAddress |
    Select-Object @{Name = "ExternalRecipient"; Expression = { $_.Name }}, Count |
    Export-Csv -NoTypeInformation -Path $PathCsvSingle -Encoding utf8

Write-Host "Report exported to: $PathCsvSingle" -ForegroundColor Green

# -----------------------------------------------------------------------------
# Scenario 2: Filter external recipients across multiple internal domains
# -----------------------------------------------------------------------------
$InternalDomains = @("domain.com", "domain2.com", "domain3.com", "tenant.onmicrosoft.com")
$PathCsvMulti = "$env:USERPROFILE\Downloads\ExportMsgTraceUniqueExternalAddresses_MultiDomain_$((Get-Date -Format 'yyyyMMddHHmmss')).csv"

Write-Host "Querying message trace with multi-domain exclusion list..." -ForegroundColor Cyan
Get-MessageTrace -StartDate (Get-Date).AddDays(-30) -EndDate (Get-Date) |
    Where-Object {
        $recipient = $_.RecipientAddress
        $isInternal = $false
        foreach ($d in $InternalDomains) {
            if ($recipient -like "*@$d" -or $recipient -like "*$d") {
                $isInternal = $true
                break
            }
        }
        -not $isInternal
    } |
    Group-Object -Property RecipientAddress |
    Select-Object @{Name = "ExternalRecipient"; Expression = { $_.Name }}, Count |
    Export-Csv -NoTypeInformation -Path $PathCsvMulti -Encoding utf8

Write-Host "Multi-domain report exported to: $PathCsvMulti" -ForegroundColor Green
