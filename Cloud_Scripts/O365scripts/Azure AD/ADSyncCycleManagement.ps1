<#
.SYNOPSIS
    Manages Microsoft Entra Connect (Azure AD Connect) synchronization cycles and scheduler settings.

.DESCRIPTION
    Provides administrative controls for Microsoft Entra Connect sync on the local staging or active
    sync server. Supports triggering Full (Initial) sync, Delta sync, configuring customized synchronization
    intervals, and pausing or resuming the sync scheduler service.

.PARAMETER SyncType
    Specifies the type of sync cycle to trigger: 'Delta', 'Initial' (Full), or 'None'. Defaults to 'Delta'.

.PARAMETER CustomInterval
    Optional TimeSpan string (e.g., '00:30:00' for 30 minutes) to adjust sync interval.

.PARAMETER SuspendSync
    Switch to suspend the Entra Connect sync scheduler.

.PARAMETER ResumeSync
    Switch to resume the Entra Connect sync scheduler.

.NOTES
    Must be executed locally on the Windows Server hosting Microsoft Entra Connect with local Administrator rights.
    Requires ADSync module.
    Author: Josep Canas - M365 Solutions Architect

.EXAMPLE
    .\ADSyncCycleManagement.ps1 -SyncType Delta
    Triggers an immediate Delta synchronization cycle to Microsoft Entra ID.

.EXAMPLE
    .\ADSyncCycleManagement.ps1 -SyncType Initial
    Triggers a full directory synchronization cycle.

.LINK
    https://learn.microsoft.com/azure/active-directory/hybrid/how-to-connect-sync-feature-scheduler
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Delta", "Initial", "None")]
    [string]$SyncType = "Delta",

    [Parameter(Mandatory = $false)]
    [string]$CustomInterval,

    [Parameter(Mandatory = $false)]
    [switch]$SuspendSync,

    [Parameter(Mandatory = $false)]
    [switch]$ResumeSync
)

# Import ADSync Module
if (-not (Get-Module -Name ADSync)) {
    Import-Module ADSync -ErrorAction Stop
}

# 1. Handle Scheduler Suspend / Resume
if ($SuspendSync) {
    Write-Host "Suspending Entra Connect sync scheduler..." -ForegroundColor Yellow
    Set-ADSyncScheduler -SyncCycleEnabled $false
}
elseif ($ResumeSync) {
    Write-Host "Resuming Entra Connect sync scheduler..." -ForegroundColor Green
    Set-ADSyncScheduler -SyncCycleEnabled $true
}

# 2. Configure Custom Sync Interval
if (-not [string]::IsNullOrWhiteSpace($CustomInterval)) {
    Write-Host "Setting customized sync cycle interval to $CustomInterval..." -ForegroundColor Cyan
    Set-ADSyncScheduler -CustomizedSyncCycleInterval $CustomInterval
}

# 3. Trigger Sync Cycle
if ($SyncType -ne "None") {
    Write-Host "Initiating $SyncType sync cycle..." -ForegroundColor Cyan
    Start-ADSyncSyncCycle -PolicyType $SyncType
    Write-Host "$SyncType synchronization initiated." -ForegroundColor Green
}

# 4. Display Current Scheduler Status
Write-Host "`n=== Current Entra Connect Scheduler Status ===" -ForegroundColor Cyan
$scheduler = Get-ADSyncScheduler
$scheduler | Select-Object SyncCycleEnabled,
                           NextSyncCycleStartTimeInUTC,
                           CurrentlyRunningNetworkPolicyCycle,
                           CustomizedSyncCycleInterval,
                           AllowedSyncCycleInterval |
             Format-List
