<#
.SYNOPSIS
    EXO-007 | Exchange Online Mailbox Type Conversion Management.

.DESCRIPTION
    PowerShell script to convert Exchange Online mailboxes between User (Regular), Room, 
    Equipment, and Shared types. Supports both interactive multi-mailbox selection and conversion 
    via Out-GridView, as well as single-mailbox target cmdlets.

.PRODUCT
    Exchange Online

.ORIGINAL_AUTHOR
    O365scripts Contributors (ExchangeOnlineMailboxConversion classification)
    Reference: https://github.com/O365scripts/O365scripts/blob/master/ExchangeOnline/ExchangeOnlineMailboxConversion.ps1

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-007 classification)

.VERSION
    1.0

.NOTES
    Name: EXO-007_Exchange-Mailbox-Conversion.ps1
    Requires: ExchangeOnlineManagement module.
    Available types for conversion:
      - Regular (User)
      - Room
      - Equipment
      - Shared
    WARNING: Shared mailboxes can store up to 50GB of data without a license. A license is required to exceed 50GB.

.PARAMETER AdminUpn
    The User Principal Name (UPN) of the Administrator account.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
$AdminUpn = ""
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Connect to EXO
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -UserPrincipalName $AdminUpn

# Interactive mailbox type conversion selection
$TypeSource = "Regular", "Room", "Equipment", "Shared" | Out-GridView -Title "Select Source Mailbox Type" -OutputMode Single
$TypeDest = "Regular", "Room", "Equipment", "Shared" | Out-GridView -Title "Select Destination Mailbox Type" -OutputMode Single

# Get the list of source mailboxes and select target ones interactively
if ($TypeSource -and $TypeDest) {
    # RecipientTypeDetails mapping helper
    $filterType = $TypeSource
    if ($filterType -eq "Regular") { $filterType = "UserMailbox" }
    elseif ($filterType -eq "Room") { $filterType = "RoomMailbox" }
    elseif ($filterType -eq "Equipment") { $filterType = "EquipmentMailbox" }
    elseif ($filterType -eq "Shared") { $filterType = "SharedMailbox" }

    $ListMbox = Get-Mailbox -ResultSize Unlimited -Filter "RecipientTypeDetails -eq '$filterType'" | 
        Select-Object Identity, PrimarySmtpAddress, RecipientTypeDetails, DistinguishedName | 
        Out-GridView -Title "Select Mailboxes to Convert to $TypeDest" -PassThru

    if ($ListMbox) {
        $ListMbox | ForEach-Object {
            Set-Mailbox -Identity $_.DistinguishedName -Type $TypeDest
        }
    }
}

# Convert a single mailbox into a different type?
# $User = "user@domain.com"
# Set-Mailbox -Identity $User -Type Shared
# Set-Mailbox -Identity $User -Type User
#endregion
