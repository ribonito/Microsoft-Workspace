<#===================================================================================================================
Script Name	: Citrix XA-XD-7.x Inventory
       Purpose	: To fetch the Citrix published application & desktop inventory over Email
Author		: Pradeep Raju - 8015648323
Date Created	: 5/3/2017

=====================================================================================================================#>
$from= read-host " Enter Sender Email ID"
$sendto= Read-host "Enter Recepient Email ID"
$subj= read-host "Enter email subject"

Add-pssnapin Citrix*
cd C:\temp
del Citrix7.8_*.csv
get-brokerapplication | Select ApplicationName,Enabled,AdminFolder,ClientFolder,CommandLineExecutable,WorkingDirectory,@{Name='AssociatedUserFullNames';Expression={[string]::join(";",($_.AssociatedUserFullNames))}} | export-csv -path C:\temp\Citrix7.8_ApplicationInventory.csv
#get-brokerentitlementpolicyrule | Select Name,includedusers,Enabled | format-table -wrap | out-file c:\temp\Citrix7.8_PublisheddesktopInventory.csv
#send-mailmessage -from $from -to $sendto -smtp $smtp -subject $subj -body "Please find the report" -attachment C:\temp\Citrix7.8_*.csv
