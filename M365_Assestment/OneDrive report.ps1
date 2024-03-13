$adminURL = ‘https://emseal-admin.sharepoint.com/'
Connect-SPOService -Url $adminURL



 $SamAccountName = Import-Csv -Path c:\temp\users.csv
 
#Domain and tenant name have to be adjusted
        $TenantName = 'parexusa'
        $DomainName = 'parexusa'

 
        foreach ($User in $SamAccountName.SamAccountName) {
            try {
                $URL = "https://$($TenantName)-my.sharepoint.com/personal/$($User)_$($DomainName)_com"
                $Stats = Get-SPOSite -Identity $URL | select Owner, StorageUsageCurrent
                [PSCustomObject]@{
                    Owner          = $Stats.Owner
                    CurrentUsageGB = "{0:F3}" -f ($Stats.StorageUsageCurrent / 1024) -as [decimal]
                    }
 
            } catch {
                Write-Error $_.Exception.Message
 
            }
        }



 



