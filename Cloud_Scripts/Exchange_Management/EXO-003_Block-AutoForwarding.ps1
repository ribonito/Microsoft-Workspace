<#
.SYNOPSIS
    EXO-003 | Exchange Online - Block External Auto-Forwarding via Transport Rule.

.DESCRIPTION
    Creates a transport rule that blocks all automatic email forwarding to external
    recipients. This is a key security control recommended by Microsoft and CIS
    benchmarks to prevent data exfiltration via mail forwarding rules.

    If the rule already exists, the script skips creation to avoid duplicates.

.PRODUCT
    Exchange Online

.AUTHOR
    Josep Canas - M365 Solutions Architect

.VERSION
    1.1

.EXAMPLE
    .\EXO-003_Block-AutoForwarding.ps1

.NOTES
    - Module: ExchangeOnlineManagement
    - Run with "Exchange Administrator" or higher
    - The rejection message is displayed to the sender when the rule fires
#>

#region ── Connection ─────────────────────────────────────────────────────────
Connect-ExchangeOnline
#endregion

#region ── Block Auto-Forwarding Transport Rule ───────────────────────────────
$ruleName      = "Block Auto-Forwarding"
$rejectMessage = "To improve security, auto-forwarding rules to external email addresses have been disabled. Please contact your helpdesk if you want to create an exception."

$existingRule = Get-TransportRule | Where-Object { $_.Identity -contains $ruleName }

if (-not $existingRule) {
    Write-Output "Auto-forwarding rule not found — creating it now."
    New-TransportRule `
        -Name                          $ruleName `
        -Priority                      1 `
        -SentToScope                   NotInOrganization `
        -FromScope                     InOrganization `
        -MessageTypeMatches            AutoForward `
        -RejectMessageEnhancedStatusCode "5.7.1" `
        -RejectMessageReasonText       $rejectMessage
    Write-Output "Rule '$ruleName' created successfully."
} else {
    Write-Output "Rule '$ruleName' already exists — no action taken."
}
#endregion
