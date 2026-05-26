If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
    }
    Catch {
        Throw "Failed to start $PSCOMMANDPATH"
    }
    Exit
}

$AppName = "MSTeams"
$ProvApp = Get-ProvisionedAppPackage -Online | Where-Object {$_.DisplayName -eq $AppName}
if ($ProvApp) {
    Write-Output "Found provisioned Teams package version: $($ProvApp.Version)"
    Exit 0
}
else {
    Exit 0
}
