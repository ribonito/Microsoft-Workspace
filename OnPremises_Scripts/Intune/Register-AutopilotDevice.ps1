[CmdletBinding()]
param(
        [Parameter(Mandatory = $false)]
        [switch]$Csv
    )

# Configuration
$ClientId = "05f7e286-a51f-4d4e-b820-da5d3167c3c7"
$TenantId = "0b57e92f-4bfc-4513-81af-dff5bed4c391"
$ClientSecret = "WUo8Q~2wxmApVln5ULJ8H6Y1qd2Dp4Hkn6nIzcdE"

#Install script
Install-PackageProvider -Name NuGet -Confirm:$false -Force:$true
Install-Script get-windowsautopilotinfo -Confirm:$false -Force:$true

# Get hardware hash and upload directly to AP
If($Csv){
    Get-WindowsAutopilotInfo -OutputFile ".\RegInfo.csv"
} else {
    get-windowsautopilotinfo -Online -TenantId $tenantId -AppId $ClientId -AppSecret $ClientSecret
}
