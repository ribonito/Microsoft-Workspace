# Detection script for rename hybrid joined device operation
# device name stored in the computer autopilot record is used to set the name of the device

if (Test-Path "HKLM:/Software/Sunrise/Manage") {
    $subKey = Get-Item "HKLM:/Software/Sunrise/Manage"
    $Value = $SubKey.GetValue("HAADJComputerRename")
    if ($Value -eq 1) {
        Write-Host "Found registry value HKLM:/Software/Sunrise/Manage/HAADJComputerRename=1. Computer rename has been completed or not required."            
        exit 0
    }
}
exit 1
