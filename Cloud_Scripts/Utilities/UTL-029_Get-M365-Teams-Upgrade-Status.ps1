<#
.SYNOPSIS
    UTL-029 | M365 Teams Upgrade Status.

.DESCRIPTION
    Report Skype-to-Teams upgrade status for users.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (UTL-029 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Tools/Get-M365TeamsUpgradeStatus.ps1

.NOTES
    Name: UTL-029_Get-M365-Teams-Upgrade-Status.ps1
    Integrated from O365scripts upstream repository.
#>

<# Confirm Tenant Upgrade Status. #>
Get-CsTeamsUpgradeStatus;
Get-CsTeamsUpgradeConfiguration -Identity Global;
Get-CsTeamsUpgradePolicy -Identity Global;

<# Sample Tenant Upgrade Status Output. #>
<#
TenantId             : x
State                : Null
OptInEligibleDate    : 
UpgradeScheduledDate : 
UserNotificationDate : 
UpgradeDate          : 
LastStateChangeDate  : 
#>

<# Confirm Teams User Upgrade Status Details. #>
$User = "";
Get-CsOnlineUser -Identity $User | Select UserPrincipalName,TeamsUpgrade*;

<# Confirm Teams Upgade Status of All Users. #>
Get-CsOnlineUser | Select ObjectId,UserPrincipalName,TeamsUpgradeEffectiveMode;
