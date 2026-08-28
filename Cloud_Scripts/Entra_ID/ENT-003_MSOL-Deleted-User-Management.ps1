<#
.SYNOPSIS
    ENT-003 | MSOL Deleted User Management.

.DESCRIPTION
    List, restore, and permanently delete soft-deleted users.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (ENT-003 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Online/MSOL%20-%20Deleted%20User%20Management.ps1

.NOTES
    Name: ENT-003_MSOL-Deleted-User-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to MSOL. #>
Connect-MsolService;
#Connect-MsolService -Credential $Creds;

<# WARNING: Get list of DELETED accounts and purge selected one(s) PERMANENTLY! #>
$users = Get-MsolUser -All -ReturnDeletedUsers | Select-Object Displayname,UserPrincipalName,ObjectID,WhenCreated | Out-GridView -PassThru -Title "Select which account(s) you wish to permanently remove...";
if ($null -ne $users) {
	Write-Host -Fore Red -NoNewline "WARNING: ";
	Write-Host -Fore Yellow -NoNewline "Are you certain you wish to proceed with purging the selected deleted accounts permanently? ";
	$input = Read-Host;
	if ($input -like "yes") {
		if ($users -is [array]) {
			foreach ($u in $users) {
				Write-Host -Fore Yellow -NoNewline "Purging: "; Write-Host $u.UserPrincipalName;
				Remove-MsolUser -ObjectId $u.ObjectId -RemoveFromRecycleBin -Force -WhatIf;
			}
		}
		else {
			Write-Host -Fore Yellow -NoNewline "Purging: "; Write-Host $users.UserPrincipalName;
			Remove-MsolUser -ObjectId $users.ObjectId -RemoveFromRecycleBin -Force -WhatIf;
			}
		}
	else {Write-Host "Purge cancelled.";}
	}
