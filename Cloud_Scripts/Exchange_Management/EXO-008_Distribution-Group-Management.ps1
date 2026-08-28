<#
.SYNOPSIS
    EXO-008 | Distribution Group Management.

.DESCRIPTION
    Full distribution group membership overview and CSV export.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (EXO-008 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Exchange%20Online/EXO%20-%20Distribution%20Group%20Management.ps1

.NOTES
    Name: EXO-008_Distribution-Group-Management.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to EXO v2. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module ExchangeOnlineManagement -AllowClobber -Force -Confirm:$false;
$AdminUpn = "";
Connect-ExchangeOnline -UserPrincipalName $AdminUpn;

<# Full Distribution Group Membership Overview. #>
$report = @();
$list_dg = Get-DistributionGroup -ResultSize Unlimited;
$count_dg = $groups.Count;
$i = 1;
$list_dg | % {
    Write-Progress -Activity "Exporting list of members from $_" -Status "$i out of $count_dg distribution groups.";
    $group = $_;
    Get-DistributionGroupMember -Identity $group.Name -ResultSize Unlimited | ForEach-Object {
        $member = $_
        $report += New-Object PSObject -Property @{
            GroupDisplayName    = $group.DisplayName
            GroupPrimarySmtp    = $group.PrimarySmtpAddress
            MemberDisplayName   = $member.DisplayName
            MemberPrimarySmtp   = $member.PrimarySMTPAddress
            MemberRecipientType = $member.RecipientType
            }
        }
    $i++
    };

<# Preview results? #>
$report | Out-GridView;

<# Export results to CSV file. #>
$path_csvout = "$env:USERPROFILE\Desktop\list_dgmembers.csv"
$report | Export-Csv -Path $path_csvout -NoTypeInformation -Force;
