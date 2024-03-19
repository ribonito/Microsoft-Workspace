# Connect to SharePoint Online administration endpoint
Import-Module -Name Microsoft.Online.SharePoint.PowerShell
Connect-SPOService -URL "https://hawlech-admin.sharepoint.com/" 

# Get a list of OneDrive for Business sites in the tenant sorted by the biggest consumer of quota
Write-Host "Finding OneDrive sites..."
[array]$ODFBSites = Get-SPOSite -IncludePersonalSite $True -Limit All -Filter "Url -like '-my.sharepoint.com/personal/'" | Select Owner, Title, URL, StorageQuota, StorageUsageCurrent | Sort StorageUsageCurrent -Descending
If (!($ODFBSites)) { Write-Host "No OneDrive sites found (surprisingly...)" ; break }
# Calculate total used
$TotalODFBGBUsed = [Math]::Round(($ODFBSites.StorageUsageCurrent | Measure-Object -Sum).Sum /1024,2)
# Create list to store report data
$Report = [System.Collections.Generic.List[Object]]::new()
# Store information for each OneDrive site
ForEach ($Site in $ODFBSites) {
      $ReportLine   = [PSCustomObject]@{
        Owner       = $Site.Title
        Email       = $Site.Owner
        URL         = $Site.URL
        QuotaGB     = [Math]::Round($Site.StorageQuota/1024,2) 
        UsedGB      = [Math]::Round($Site.StorageUsageCurrent/1024,4)
        PercentUsed = [Math]::Round(($Site.StorageUsageCurrent/$Site.StorageQuota * 100),4) }
      $Report.Add($ReportLine) }
$Report | Export-CSV -NoTypeInformation c:\temp\OneDriveSiteConsumption.CSV
# You don't have to do this, but it's useful to view the data via Out-GridView
$Report | Sort UsedGB -Descending | Out-GridView
Write-Host "Current OneDrive for Business storage consumption is" $TotalODFBGBUsed "GB. Report is in C:\temp\OneDriveSiteConsumption.CSV"