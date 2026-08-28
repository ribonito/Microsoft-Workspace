<#
.SYNOPSIS
    M365-018 | Export Users, Licenses, and Service Plans Inventory to CSV.

.DESCRIPTION
    PowerShell script that connects to Microsoft Online Services (MSOnline) and exports 
    a detailed inventory mapping all tenant users, their assigned licenses (AccountSku), 
    and individual service plan enablement statuses to a CSV file.

.PRODUCT
    Microsoft 365 / MSOnline

.ORIGINAL_AUTHOR
    Martina Grom - atwork.at
    Based on script by Alan Byrne (https://gallery.technet.microsoft.com/scriptcenter/Export-a-Licence-b200ca2a)

.MAINTAINER
    Josep Canas - M365 Solutions Architect (M365-018 classification)

.VERSION
    1.0

.NOTES
    Name: M365-018_Export-User-Licenses-MSOnline.ps1
    Requires: MSOnline module (Connect-MsolService).
    WARNING: The MSOnline module is deprecated; transition to Microsoft.Graph is recommended.
#>

#region ── Parameters ─────────────────────────────────────────────────────────
# The Output will be written to this file in the current working directory
$LogFile = ".\Office-365-Licenses.csv"
#endregion

#region ── Main Program ───────────────────────────────────────────────────────
# Connect to Microsoft Online - if necessary... if you rerun the code, comment after first login to speed up
Connect-MsolService
Write-Host "Connecting to Office 365..."

# Get a list of all licenses that exist within the tenant
$licensetype = Get-MsolAccountSku | Where-Object { $_.ConsumedUnits -ge 1 }

# Loop through all license types found in the tenant
$i = 1
foreach ($license in $licensetype) 
{	
    # Build and write the Header for the CSV file
    $headerstring = "DisplayName,UserPrincipalName,AccountSku"

    foreach ($row in $($license.ServiceStatus)) 
    {
        $headerstring = ($headerstring + "," + $row.ServicePlan.servicename)
    }

    Out-File -FilePath $LogFile -InputObject $headerstring -Encoding UTF8

    # Now get the user licenses and plans
    Write-Host ("Gathering users with the following subscription: " + $license.accountskuid)

    # Gather users for this particular AccountSku
    $users = Get-MsolUser -All | Where-Object { $_.licenses.accountskuid -contains $license.accountskuid }

    # Loop through all users and write them to the CSV file
    foreach ($user in $users) {
        # Fix displayname for correct output in CSV...
        $dn = $($user.displayname).Replace(",", " ")
        Write-Host ("$i. $dn")
        $i++

        $thislicense = $user.licenses | Where-Object { $_.accountskuid -eq $license.accountskuid }
        $datastring = ($dn + "," + $user.userprincipalname + "," + $license.SkuPartNumber)

        foreach ($row in $($thislicense.servicestatus)) {
            # Build data string: PendingActivation, Disabled, Success - we want to sum in Excel, so we use 0 and 1...
            $st = $row.provisioningstatus
            if ($st -eq "PendingActivation") { $st = '1' }
            if ($st -eq "Success") { $st = '1' }
            if ($st -eq "Disabled") { $st = '0' }
            $datastring = ($datastring + "," + $st)
        }
		
        Out-File -FilePath $LogFile -InputObject $datastring -Encoding UTF8 -Append
    }
}			

# Users without license
if (1 -eq 1) {
    $users = Get-MsolUser -All | Where-Object { $_.isLicensed -ne "True" }
    foreach ($user in $users) {
        $dn = $($user.DisplayName).Replace(",", " ")
        Write-Host ("$i. $dn")
        $i++
        $datastring = ($dn + "," + $user.userprincipalname + ",No License")
        Out-File -FilePath $LogFile -InputObject $datastring -Encoding UTF8 -Append
    }
}

Write-Host ("Done. Check " + $LogFile)
#endregion
