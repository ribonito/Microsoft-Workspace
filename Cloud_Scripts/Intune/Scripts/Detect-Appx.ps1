$appId = "Microsoft.CompanyPortal"
$AppPkgs = Get-AppxPackage -allusers $appId
If ($AppPkgs){
    Write-Output "Found $appId"
    Exit 0
}
else {
    Exit 0
}        
