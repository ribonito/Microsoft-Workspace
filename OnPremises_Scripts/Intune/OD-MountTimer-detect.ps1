$Path = "HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1"
$Name = "Timerautomount"
$Type = "QWORD"
$Value = 1

Try {
    $Registry = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop | Select-Object -ExpandProperty $Name
    If ($Registry -eq $Value){
        Write-Output "Timer Automount Set to zero"
        Exit 0
    } 
    Write-Warning "Timer Automount Not configured to zero"
    Exit 1
} 
Catch {
    Write-Warning "Another Issue Occured"
    Exit 1
}