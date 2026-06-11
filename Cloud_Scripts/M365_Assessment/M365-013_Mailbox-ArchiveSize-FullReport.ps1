<#
.SYNOPSIS
    M365-013 | M365 Assessment - Mailbox and Archive Size Report (Full, with Shared Mailboxes).

.DESCRIPTION
    Generates a comprehensive CSV report of all mailbox sizes in Exchange Online,
    including primary mailbox and archive statistics. Supports filtering by mailbox type
    (user, shared, or both) and optional archive inclusion.

    Output columns per mailbox:
        - Display Name / Email Address / Mailbox Type
        - Last User Action Time
        - Total Size (GB) / Deleted Items Size (GB) / Item Count
        - Mailbox Warning Quota / Max Mailbox Size (GB)
        - Archive Size (GB) / Archive Item Count / Archive Quota (GB)

    Useful for Exchange Online license planning (E1/E3/E5),
    mailbox migration sizing, and governance audits.

.PRODUCT
    Exchange Online

.ORIGINAL_AUTHOR
    R. Mens - LazyAdmin.nl
    Version: 1.1 | Creation: 23 Sep 2021
    Purpose/Change: Added Item Count and User last action time
    Reference: https://lazyadmin.nl/powershell/office-365-mailbox-size-report

.MAINTAINER
    Josep Canas - M365 Solutions Architect (M365-013 classification & English header)

.VERSION
    1.2

.PARAMETER adminUPN
    UPN of the Exchange Online or Global Administrator account.

.PARAMETER sharedMailboxes
    "include" (default) = include shared mailboxes | "only" = only shared | "no" = only user mailboxes.

.PARAMETER archive
    Switch. Include archive mailbox statistics. Default: enabled.

.PARAMETER path
    Output CSV file path. Defaults to script root + date-stamped filename.

.EXAMPLE
    .\M365-013_Mailbox-ArchiveSize-FullReport.ps1 -adminUPN admin@contoso.com

.EXAMPLE
    .\M365-013_Mailbox-ArchiveSize-FullReport.ps1 -adminUPN admin@contoso.com -sharedMailboxes only

.EXAMPLE
    .\M365-013_Mailbox-ArchiveSize-FullReport.ps1 -adminUPN admin@contoso.com -sharedMailboxes no -archive:$false

.NOTES
    Module: ExchangeOnlineManagement
#>

#region ── Parameters ─────────────────────────────────────────────────────────
param(
  [Parameter(
    Mandatory = $true,
    HelpMessage = "Enter the Exchange Online or Global admin username"
  )]
  [string]$adminUPN,

  [Parameter(
    Mandatory = $false,
    HelpMessage = "Get (only) Shared Mailboxes or not. Default include them"
  )]
  [ValidateSet("no", "only", "include")]
  [string]$sharedMailboxes = "include",

  [Parameter(
    Mandatory = $false,
    HelpMessage = "Include Archive mailboxes"
  )]
  [switch]$archive = $true,

  [Parameter(
    Mandatory = $false,
    HelpMessage = "Enter path to save the CSV file"
  )]
  [string]$path = ".\MailboxSizeReport-$((Get-Date -format "MMM-dd-yyyy").ToString()).csv"
)
#endregion

#region ── Helper Functions ───────────────────────────────────────────────────
Function ConnectTo-EXO {
  <#
    .SYNOPSIS
        Connects to EXO when no connection exists. Checks for EXO v2 module
  #>
  
  process {
    # Check if EXO is installed and connect if no connection exists
    if ((Get-Module -ListAvailable -Name ExchangeOnlineManagement) -eq $null)
    {
      Write-Host "Exchange Online PowerShell v2 module is required, do you want to install it?" -ForegroundColor Yellow
      
      $install = Read-Host Do you want to install module? [Y] Yes [N] No 
      if($install -match "[yY]") 
      { 
        Write-Host "Installing Exchange Online PowerShell v2 module" -ForegroundColor Cyan
        Install-Module ExchangeOnlineManagement -Repository PSGallery -AllowClobber -Force
      } 
      else
      {
	      Write-Error "Please install EXO v2 module."
      }
    }


    if ((Get-Module -ListAvailable -Name ExchangeOnlineManagement) -ne $null) 
    {
	    # Check if there is a active EXO sessions
	    $psSessions = Get-PSSession | Select-Object -Property State, Name
      If ($psSessions -notmatch 'Opened.*ExchangeOnlineInternalSession') {
		    Connect-ExchangeOnline -UserPrincipalName $adminUPN
	    }
    }
    else{
      Write-Error "Please install EXO v2 module."
    }
  }
}

Function Get-Mailboxes {
  <#
    .SYNOPSIS
        Get all the mailboxes for the report
  #>
  process {
    switch ($sharedMailboxes)
    {
      "include" {$mailboxTypes = "UserMailbox,SharedMailbox"}
      "only" {$mailboxTypes = "SharedMailbox"}
      "no" {$mailboxTypes = "UserMailbox"}
    }

    Get-EXOMailbox -ResultSize unlimited -RecipientTypeDetails $mailboxTypes -Properties IssueWarningQuota, ProhibitSendReceiveQuota, ArchiveQuota, ArchiveWarningQuota, ArchiveDatabase | 
      select UserPrincipalName, DisplayName, PrimarySMTPAddress, RecipientType, RecipientTypeDetails, IssueWarningQuota, ProhibitSendReceiveQuota, ArchiveQuota, ArchiveWarningQuota, ArchiveDatabase
  }
}

Function ConvertTo-Gb {
  <#
    .SYNOPSIS
        Convert mailbox size to Gb for uniform reporting.
  #>
  param(
    [Parameter(
      Mandatory = $true
    )]
    [string]$size
  )
  process {
    if ($size -ne $null) {
      $value = $size.Split(" ")

      switch($value[1]) {
        "GB" {$sizeInGb = ($value[0])}
        "MB" {$sizeInGb = ($value[0] / 1024)}
        "KB" {$sizeInGb = ($value[0] / 1024 / 1024)}
      }

      return [Math]::Round($sizeInGb,2,[MidPointRounding]::AwayFromZero)
    }
  }
}


Function Get-MailboxStats {
  <#
    .SYNOPSIS
        Get the mailbox size and quota
  #>
  process {
    $mailboxes = Get-Mailboxes
    $i = 0

    $mailboxes | ForEach {

      # Get mailbox size     
      $mailboxSize = Get-MailboxStatistics -identity $_.UserPrincipalName | Select TotalItemSize,TotalDeletedItemSize,ItemCount,DeletedItemCount,LastUserActionTime
      
      # Get archive size if it exists and is requested
      $archiveSize = 0
      $archiveResult = $null

      if ($archive.IsPresent -and ($_.ArchiveDatabase -ne $null)) {
        $archiveResult = Get-EXOMailboxStatistics -UserPrincipalName $_.UserPrincipalName -Archive | Select ItemCount,DeletedItemCount,@{Name = "TotalArchiveSize"; Expression = {$_.TotalItemSize.ToString().Split("(")[0]}}
        if ($archiveResult -ne $null) {
          $archiveSize = ConvertTo-Gb -size $archiveResult.TotalArchiveSize
        }else{
          $archiveSize = 0
        }
      }  
    
      [pscustomobject]@{
        "Display Name" = $_.DisplayName
        "Emailaddress" = $_.PrimarySMTPAddress
        "Mailbox type" = $_.RecipientTypeDetails
        "Last user action time" = $mailboxSize.LastUserActionTime
        "Total size (Gb)" = ConvertTo-Gb -size $mailboxSize.TotalItemSize.ToString().Split("(")[0]
        "Delete item size (Gb)" = ConvertTo-Gb -size $mailboxSize.TotalDeletedItemSize.ToString().Split("(")[0]
        "Item Count" = $mailboxSize.ItemCount
        "Deleted Item Count" = $mailboxSize.DeletedItemCount
        "Mailbox Warning quota (GB)" = $_.IssueWarningQuota.ToString().Split("(")[0]
        "Max mailbox size (Gb)" = $_.ProhibitSendReceiveQuota.ToString().Split("(")[0]
        "Archive size (Gb)" = $archiveSize
        "Archive Item Count" = if ($archiveResult) { $archiveResult.ItemCount } else { 0 }
        "Archive Deleted Item Count" = if ($archiveResult) { $archiveResult.DeletedItemCount } else { 0 }
        "Archive Warning quota (GB)" = $_.ArchiveWarningQuota.ToString().Split("(")[0]
        "Archive quota (Gb)" = ConvertTo-Gb -size $_.ArchiveQuota.ToString().Split("(")[0]
      }

      $currentUser = $_.DisplayName
      Write-Progress -Activity "Collecting mailbox status" -Status "Current Count: $i" -PercentComplete (($i / $mailboxes.Count) * 100) -CurrentOperation "Processing mailbox: $currentUser"
      $i++;
    }
  }
}
#endregion

#region ── Authentication ─────────────────────────────────────────────────────
# Connect to Exchange Online
ConnectTo-EXO
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Get mailbox status
Get-MailboxStats | Export-CSV -Path $path -NoTypeInformation

if ((Get-Item $path).Length -gt 0) {
  Write-Host "Report finished and saved in $path" -ForegroundColor Green
}else{
  Write-Host "Failed to create report" -ForegroundColor Red
}

# Close Exchange Online Connection
$close = Read-Host Close Exchange Online connection? [Y] Yes [N] No 

if ($close -match "[yY]") {
  Disconnect-ExchangeOnline -Confirm:$false | Out-Null
}
#endregion