# Bellow 2 commented commands are required only once
 
# Install-Module -Name PartnerCenter -AllowClobber
# Import-Module PartnerCenter 
# Connect to partner center 
Connect-PartnerCenter
 
Function Get-User-From-PartnerCenter {
[cmdletbinding()]
Param (
[parameter(Mandatory=$true)]
[string]$csvPath,
[string]$userName
)
# End of Parameters
 Process {
         $Result = ""   
         $Results = @() 
         $ErrorActionPreference = "Stop"
 
         # Get all tenats in Partner center
 
         $Customers = Get-PartnerCustomer
 
         # Search every tenant for specific user
 
         $Customers.ForEach({
 
         Try{
                $CustId = $_.CustomerId
                $CustName = $_.Name
                $CustomerUser = Get-PartnerCustomerUser -CustomerId $CustId | Where-Object {
                $_.DisplayName -like "*$userName*"
                } | ForEach-Object { New-Object -TypeName PSCustomObject -Property @{
                Name = $_.DisplayName
                'User Principal Name' = $_.UserPrincipalName
                }
               }
                
               # If user is found, Write it to CSV file
 
                if($CustomerUser -notlike ''){
                  $Result = @{'Customer Name' = $CustName; 'User Name' = $CustomerUser.Name; 'User Principal Name' = $CustomerUser.'User Principal Name'}
                  $Results += New-Object PSObject -Property $Result
                  $Results = $Results | Select-Object 'Customer Name','User Name','User Principal Name' | Export-Csv -Path $csvPath -Notype -append
                }
         }
             
         Catch{
 
               Write-Warning "Caught an exception:"
               Write-Warning "Exception Type: $($_.Exception.GetType().FullName)"
               Write-Warning "Exception Message: $($_.Exception.Message) - Tenant:$CustName"
          }
         }
       )
     }
    }