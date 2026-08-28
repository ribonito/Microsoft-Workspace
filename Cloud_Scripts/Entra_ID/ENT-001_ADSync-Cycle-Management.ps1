<#
.SYNOPSIS
    ENT-001 | ADSync Cycle Management.

.DESCRIPTION
    Start full/delta sync and configure Azure AD Connect scheduler.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (ENT-001 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Azure%20AD/ADSyncCycleManagement.ps1

.NOTES
    Name: ENT-001_ADSync-Cycle-Management.ps1
    Integrated from O365scripts upstream repository.
#>

# Start a full sync.
Import-Module ADSync
Start-ADSyncSyncCycle Initial

# Start a delta sync.
Import-Module ADSync
Start-ADSyncSyncCycle Delta

# Set a custom sync interval.
#$time = "d.HH:mm:ss" # Format to use.
#$time = "2.0:00:00" # 2d
#$time = "12:00:00" # 12h
#$time = "0:30:00" # 30m
$time = ""
Set-ADSyncScheduler -CustomizedSyncCycleInterval $time
Get-ADSyncScheduler.CustomizedSyncCycleInterval

# Toggle the sync service.
Set-ADSyncScheduler -SyncCycleEnabled $false
Set-ADSyncScheduler -SyncCycleEnabled $true
