<#
.SYNOPSIS
    TEA-005 | Set Microsoft Teams Information Retention Policy.

.DESCRIPTION
    PowerShell script that assigns a specific Microsoft 365 compliance retention policy to a 
    specific Microsoft Team. It establishes connections to Microsoft Teams and the Security & Compliance 
    Center, and verifies/distributes policy changes.

.PRODUCT
    Microsoft Teams / Microsoft Purview Compliance

.ORIGINAL_AUTHOR
    Christoph Wilfing, Toni Pohl, Martina Grom - atwork.at

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-005 classification)

.VERSION
    1.0

.NOTES
    Name: TEA-005_Set-Teams-Retention-Policy.ps1
    Requires: MicrosoftTeams module, Exchange Online / Compliance module.
#>

#Requires -Module MicrosoftTeams
#Requires -PSEdition Desktop
#Requires -Version 5.1

#region ── Main Program ───────────────────────────────────────────────────────
# Direct mode (not in Azure Automation)
if ($Null -eq $cred) {
    $cred = Get-Credential -Message 'Input Admin credentials to access the Microsoft 365 Tenant'
    # Useful modules...
    Connect-AzureAD -Credential $cred
    Connect-MicrosoftTeams -Credential $cred
    # Connect to the Security Center Powershell.
    # Notes for the account: No MFA, Basic authentication must be enabled, sufficient permissions
    Import-PSSession ( `
            New-PSSession `
            -ConfigurationName Microsoft.Exchange `
            -ConnectionUri https://ps.compliance.protection.outlook.com/powershell-liveid/ `
            -Credential $cred `
            -Authentication Basic `
            -AllowRedirection `
            -Name 'Security' ) `
        -AllowClobber | Out-Null 
}

# Retrieve all retention policies (if we need the list later...)
$RetentionPolicyList = Get-RetentionCompliancePolicy -DistributionDetail

# Get a specific policy
$OnePolicy = $RetentionPolicyList | Where-Object { $_.Name -eq "<PolicyName1>" }

# Get all teams
$TeamList = Get-Team

# Get a specific team
$OneTeam = $TeamList | Where-Object { $_.DisplayName -eq "<TeamName1>" }

# Set the policy to a team (there could be more policies assigned already - this case is ignored here)
Set-RetentionCompliancePolicy -Identity $OnePolicy.Id -AddTeamsChannelLocation $OneTeam.GroupId

# Check it: Refresh the policy list
$RetentionPolicyList = Get-RetentionCompliancePolicy -DistributionDetail

# TeamsChannelLocation.ImmutableIdentity contains the Teams.GroupId if a policy is assigned
$AssignedPolicies = $RetentionPolicyList | Where-Object { $_.teamschannellocation.ImmutableIdentity -eq $OneTeam.GroupId }

# Show the assigned policies of $OneTeam
$AssignedPolicies | Format-List
#endregion
