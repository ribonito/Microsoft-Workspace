<#
.SYNOPSIS
    TEA-021 | Telephone Number Portability Test.

.DESCRIPTION
    Run number portability validation tests.

.PRODUCT
    Microsoft 365

.ORIGINAL_AUTHOR
    O365scripts Community - github.com/O365scripts/O365scripts

.MAINTAINER
    Josep Canas - M365 Solutions Architect (TEA-021 classification)

.VERSION
    1.0

.LINK
    https://github.com/O365scripts/O365scripts/blob/master/Microsoft%20Teams/Teams%20-%20Telephone%20Number%20Portability%20Test.ps1

.NOTES
    Name: TEA-021_Telephone-Number-Portability-Test.ps1
    Integrated from O365scripts upstream repository.
#>

<# Connect to Teams. #>
#Set-ExecutionPolicy RemoteSigned -Force -Confirm:$false;
#Install-Module MicrosoftTeams -AllowClobber -Force -Confirm:$false;
Import-Module MicrosoftTeams;
Connect-MicrosoftTeams;

<# Verify basic portability number details. #>
$Number = "12223334444";
$TestPortIn = Test-CsOnlineCarrierPortabilityIn -TelephoneNumbers $Number;
Write-Host -NoNewline "Available Porting Days (Mon-Fri): "; Write-Host -Fore Yellow $TestPortIn.Carriers.FocDates;
Write-Host -NoNewline "Available Porting Hours: "; Write-Host -Fore Yellow "$($TestPortIn.Carriers.FocTimeRange.Begin) - $($TestPortIn.Carriers.FocTimeRange.End)";
Write-Host -NoNewline "Minimum Porting Interval: "; Write-Host -Fore Yellow "$($TestPortIn.Carriers.MinimumPortingInterval) days";
